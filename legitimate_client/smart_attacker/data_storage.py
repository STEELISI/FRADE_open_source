import copy
import logging
from shove import Shove
from collections import deque
from heapq import heappush, heappop

class SessionException(Exception):
    pass

class Event(object):
    url = ""
    wait = 0
    ip = ""
    def __init__(self, url="/", wait=0, ip="", sessionid=""):
        self.url = url
        self.wait=wait
        self.ip = ip
        self.sessionid=sessionid
    
    def __eq__(self, other):
        if other == None:
            return False 
        if self.wait == other.wait:
            return True
        else:
            return False
    
    def __lt__(self, other):
        if self.wait < other.wait:
            return True
        else:
            return False
    
    def __gt__(self, other):
        if self.wait > other.wait:
            return True
        else:
            return False

class SessionBank(object):
    def __init__(self):
        # We can keep track of events in any Shove supported backend.
        # SQLite provides fast access for a larger number of events
        # than a plain dictionary, but may be slower than a python dict 
        # for smaller sets of events.
        self.sessions = Shove('lite:///mnt/bla.sqlite', 'lite://')
        #self.sessions = dict()
        
        # Init
        self.total_sessions = 0
        self.session_pointer = 0
        self.session_to_id = {}
        
        
        # Can be changed to provide a more randomized
        # replaying of sessions.
        self.session_skip = 1
    
    def add_session(self, events, id=""):
        self.sessions[self.total_sessions] = events
        self.session_to_id[self.total_sessions] = id
        self.total_sessions = self.total_sessions + 1
        
    def return_session(self):
        if self.total_sessions == 0:
            print("No sessions available to return.")
            return deque([]),-1
        if self.total_sessions > self.session_pointer:
            s = copy.deepcopy(self.sessions[self.session_pointer])
            id = self.session_to_id[self.session_pointer]
            self.session_pointer = self.session_pointer + self.session_skip
            return s, id
        else:
            print("Looped sessions")
            self.session_pointer = 1
            s = copy.deepcopy(self.sessions[0])
            id = self.session_to_id[0]
            return s, id 

    def print_sessions(self):
        for client in self.sessions:
            print("%s" % client)
            for e in self.sessions[client]:
                print("\t%d %s " % (e.wait, e.url))

class EventBank(object):

    def __init__(self, session_goal, session_bank, ips, timeout=5, debug=False):
        self.session_count = 0
        self.session_goal = session_goal
        self.session_bank = session_bank
        self.ips = ips
        self.event_list = []
        self.cur_ip_pointer = 0
        self.cur_ips = []
        self.timeout = timeout
        self.debug = debug
        if debug:
            self.log = logging.getLogger('rundebug')
        if len(ips) < self.session_goal:
            raise(SessionException("Not enough IPs to enact %d sessions (only have %d IPs)" %(session_goal, len(ips))))
    
    def current_session_count(self):
        return self.session_count
    
    def next_ip(self):
        ip = self.ips[self.cur_ip_pointer]
        # Start where we left off last time in the list
        # and walk the list looking for an IP that isn't currently being used (ie it's not in self.cur_ips.)
        while ip in self.cur_ips:
            self.cur_ip_pointer = self.cur_ip_pointer + 1
            if self.cur_ip_pointer >= len(self.ips):
                self.cur_ip_pointer = 0 
                print("Looped through IPs")
            ip = self.ips[self.cur_ip_pointer]
        self.cur_ips.append(ip)
        return(ip)
    
    def start_session(self, time):
        if self.session_count < self.session_goal:
            #print("Pulling from session bank.")
            events, id = self.session_bank.return_session()
            if len(events) > 0:
                self.session_count = self.session_count + 1
                
                # Get an unused IP for this session.
                session_ip = self.next_ip()
                
                # Add our dummy end event.
                last_event = Event(url="::END::", wait=self.timeout, ip=session_ip)
                events.append(last_event)
                
                # Keep track of the time of the last event we've added.
                # Initialize to the start time of this event series.
                last_event_time = time
                
                for e in events:
                    e.ip = session_ip
                    e.wait = e.wait + last_event_time + 2
                    last_event_time = e.wait
                    heappush(self.event_list, e)

                # Debug logging
                if self.debug:
                    self.log.info("Using %s to replay %d events from original client %s starting at time %s, last event@ %s, dur: %ds" % (session_ip, len(events), id, str(int(time)), str(int(last_event_time)), int(last_event_time)-int(time)))
                #print('Added new session.')

    def end_session(self, e):
        if e.url == "::END::":
            #print("Ended session for %s" % e.ip)
            self.cur_ips.remove(e.ip)
            self.session_count = self.session_count - 1

    def replace_event(self, e):
         heappush(self.event_list, e) 

    def next_request(self):
        next = None
        try:
            next = heappop(self.event_list)
        except IndexError:
            pass
        return next
        
def main():
    return
        
if __name__ == '__main__':
    main()
