from time import mktime
from collections import deque
from dateutil.parser import parse
import datetime
import logging
from data_storage import SessionBank, Event, EventBank
from time import time, sleep, strptime

MAX_WAIT = 500
MIN_WAIT = 0
clients = {}
last_time_stamp = {}
restart=0

class ApacheLogParser(object):
    def __init__(self, logs, treat_logs_as_separate=True):
        # Treat logs as separate means for each new log file, we
        # change client names between files. In otherwords,
        # we do not expect sessions to span multiple log files.
        self.treat_logs_as_separate = treat_logs_as_separate
        
        self.log_list = logs
        
        # We start out with everything in a dictionary.
        # We could keep this in a Python dict for the entire program
        # but the theory is this will eat up memory when we don't need
        # to do so?
        self.sessions = {}
        
        i=0
        for log in self.log_list:
            self.parse_log(log,i)
            i = i+1
        
    def return_dict(self):
        return self.sessions
    
    def put_session_into_storage(self, storage):
        for client in self.sessions:
            storage.add_session(self.sessions[client], id=client)

    def parse_log(self, log, index=0):
        # Should not change between apache logs, but if so, here's where to fix:
        #180.215.122.24 1491064102783 - 408 31
        #64.233.173.155 1490983542435 GET /mediawiki/index.php/Main_Page HTTP/1.1 200 126137
        global restart
        global clients
        global last_time_stamp
        print("Resrart ", restart)
        if restart == 0:
            restart = 1
            CLIENT_FIELD=0
            TIME_FIELD=1
            MESSY_CODE_FIELD=3
            URL_FIELD=3
        
            try:
                f = open(log, 'r')
            except IOError:
                print("Could not read apache log file: %s" % (log))
                exit()
        
        #clients = {}
    
            for line in f.readlines():
                try:
            
                # We assume the log file is time ordered.
                    client = line.split()[CLIENT_FIELD]
                    if self.treat_logs_as_separate:
                        client = client+'-'+str(index)
                    code = line.split()[MESSY_CODE_FIELD]
                    if (code.startswith("4")):
                        continue
                    req_time = line.split()[TIME_FIELD]
                    req_url = line.split()[URL_FIELD]
                
                    if "http://" in req_url:
                    # Need to remove pattern like: http://155.98.36.64:80/
                        req_url = '/'+'/'.join(req_url.split('/')[3:])
                
                    if client not in clients:
                        clients[client] = deque()
                    clients[client].append(req_time)
                    clients[client].append(req_url)
                    
                except Exception as e:
                    print("Could not parse apache log file line: %s" % (line))
                    print(e)
                    pass
        
        # Turn absolute time stamps into wait-times
        num_sessions = 0
        #last_time_stamp = {}
        ii=0
        while True:
            count=0
            ii=ii+1
            for client in clients:
                print("Extracting session for client %s" % client)
                #last_time_stamp = None
                while True:
                    try:
                        time = clients[client].popleft()
                    except IndexError:
                        break
                    try:
                        url = clients[client].popleft()
                    except IndexError:
                        print("WARNING: Could not find url to match with time inserted in queue for client %s!" % client)
                        break
                
                    if ii == 1:
                        last_time_stamp[client] = time
                        wait = 0
                    else:
                        wait = None
                        wait = self.diff_timestamps(last_time_stamp[client], time)
                        last_time_stamp[client] = time
                    if wait == None:
                        print("WARNING: Unable to get timestamps out of: %s and %s" % (last_time_stamp[client], time))
                        wait = 0
                    elif wait <= MAX_WAIT and wait >= MIN_WAIT:
                        count=1
                    # If our wait time looks reasonable, we can add this url to the session queue.
                        if client not in self.sessions:
                            self.sessions[client] = deque()
                            num_sessions = num_sessions + 1
                        event = Event(url=url, wait=wait)
                        self.sessions[client].append(event)
                    break    
            if count == 0:
                restart = 0        
            if ii == 1:
                break        
        print("Extracted %d sessions from web log %s" % (num_sessions, log))
                    
    
    def diff_timestamps(self, t1, t2):
        # We don't know what format these are in, so guess.
        try:
            datetime.datetime.fromtimestamp(int(t1)).strftime('%Y-%m-%d %H:%M:%S')
            datetime.datetime.fromtimestamp(int(t2)).strftime('%Y-%m-%d %H:%M:%S') 
        except ValueError as e:
            if("year is out of range" in "%s"%e):
                diff = abs(int(t2)-int(t1))
                return (diff/1000)
            else:
                print("Not given unix timestamps, will use dateutil.parser.: %s" % e)
            pass
        else:	
            diff = abs(int(t2)-int(t1))
            return diff
        
        try:
            dt1 = parse(t1, fuzzy=True)
            dt2 = parse(t2, fuzzy=True)
            diff = abs(mktime(dt2.timetuple()) - mktime(dt1.timetuple()))
            return diff
        except:
            return None
    
    def print_sessions(self):
        for client in self.sessions:
            print("CLIENT %s:" % client)
            for event in self.sessions[client]:
                print("\t%d %s" % (event.wait, event.url))
    
    def log_sessions(self):
        slog = logging.getLogger('sessions')
        slog.info("# Extracted Sessions from: %s" % ' '.join(self.log_list))
        for client in self.sessions:
            slog.info("CLIENT: %s, %d events" % (client, len(self.sessions[client])))
            for event in self.sessions[client]:
                slog.info("\t%d %s" % (event.wait, event.url))
    
def main():
    # Stub for testing.
    ap = ApacheLogParser(["test.log"])    
    s = SessionBank()
    ap.put_session_into_storage(s)
    #s.print_sessions()
    try:
        test_ips = []
        for x in range(0,261):
            test_ips.append("%s.%s.%s.%s" % (x,x,x,x))
        eb = EventBank(250, s, test_ips)
    except Exception as e:
        print(e)
        exit()
    t = time()
    eb.start_session(t)
    next = eb.next_request()
    while next != None:
        if next.wait <= t:
            if next.url != "::END::":
                #print("%.2f %s %s %.2f" %(t, next.ip, next.url, next.wait))
                pass
            else:
                eb.end_session(next)
        else:
            # Put event back in queue (heap).
            eb.replace_event(next)
            print("Sleeping. %d sessions current. Next event in %.2fs" % (eb.current_session_count(), next.wait-t))
            sleep(1)
        t = time()
        eb.start_session(t)
        next = eb.next_request()
     
if __name__ == '__main__':
    main()
