To run: 

sudo python3.4 leg_attack.py -s {SERVER} --sessions {NUMBER} --logs {LIST OF
APACHE LOGS}

 eg:

sudo python3.4 leg_attack.py -s imgur --sessions 200 --logs test.log 

You can put a list of logs as long as they are logs for the same server.
Right now, the program treats IPs seen across multiple logs as separate
entities (e.g. the requests from IP X in log file A and log file B will
result in two sessions - one from X and one from A).

WARNING: To use a specific range of IPs we may need to modify the code (since this
still has the attackII.py hack of regex'ing "10.2" for the IPs used in the
script). 

Other options are documented in the usage (so run "sudo python3.4
leg_attack.py --help" to see).

usage: leg_attack.py [-h] --server SERVER --sessions NUM_SESSIONS --logs
LOGS
                     [LOGS ...] [--interface DEVICE] [--maxopen MAX_OPEN]
                     [--timeout TIMEOUT] [--duration DURATION] [--debug]

Asynchronous, single-thread HTTP client attack tool.

optional arguments:
  -h, --help            show this help message and exit
  --server SERVER, -s SERVER	
			Server to target.
  --sessions NUM_SESSIONS, -n NUM_SESSIONS
                        Number of sessions to maintain.
  --logs LOGS [LOGS ...], -l LOGS [LOGS ...]
                        File with urls to pull from. If no file is
			specified, requests are made to root.
  --interface DEVICE, -i DEVICE
                        Optionally used to specify which device to send
                        requests out of. Eg "eth0". By default, program will
                        find device with most aliases assigned to it and use
                        that device.
  --maxopen MAX_OPEN, -m MAX_OPEN
                        The absolute max number of connections to have open.
  --timeout TIMEOUT, -t TIMEOUT
                        Time in seconds to timeout connections.
  --duration DURATION, -d DURATION
                        Duration of attack in seconds. Attack will go for
                        *approximately* this long.
  --debug, -D           Print out status messages
