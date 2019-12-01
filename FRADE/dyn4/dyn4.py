from subprocess import Popen, PIPE
import socket, struct
import time
import argparse
import re

## the data dictionary keeps track of every user
# sample: { 167837965 : (list of starttimes for five windows, list of corresponding counts, list of already seen ports) }
# The key is long format of IP address, to make lookups efficient.

intDet = 1000
attackThresh = 10
alpha = 0.9
data = {}
serverip = ""
conffile = ""
numWin = 0
winSizes = []
thresholds = []
blacklistpipe = "/tmp/dyn4"
blacklisted = set()
curSeqs = 0
avgSeqs = 0
lastDet = 0


def ip2long(ip):
	"""
	Convert an IP string to long
	"""
	packedIP = socket.inet_aton(ip)
	return struct.unpack("!L", packedIP)[0]

def blacklist(longip):
	if longip not in blacklisted:
		f = open(blacklistpipe, "w")
		f.write(str(longip)+"\n")
		f.close()
		blacklisted.add(longip)
		print str(time.time()) + ": dyn4 wrote " + socket.inet_ntoa(struct.pack('!L', longip)) + " to the blacklisting pipe\n"
		return

def dyn4(time1,longip,port,seq):
	global data

	if longip in data:
                #print("%f packet from %s:%d" %time1, longip, port);
		if port in data[longip][2]:
			return
		else:
			data[longip][2].append(port)
                        #print time1, " new connection ", longip, ":" , port
			for i in xrange(0,numWin):
				if time1 - data[longip][0][i] >= winSizes[i]: #roll over to the next window
                                        print "For ", longip, " and win ", i, " rolled over diff ",time1-data[longip][0][i]
					data[longip][0][i] = time1
					data[longip][1][i] = 1
				else:
					data[longip][1][i] += 1
                                        print "For ", longip, " and win ", i, " count is ", data[longip][1][i], " threshold ", thresholds[i]
					if data[longip][1][i] >= int(thresholds[i]):
                                                print socket.inet_ntoa(struct.pack('!L', longip))+ " " + str(time.time()) + " : threshold exceeded " + str(i)
						blacklist(longip) 
			
	else:# Initialization
		data[longip]  = ([time1]*numWin, [1]*numWin, [port])
		return
		


parser = argparse.ArgumentParser(description='Dyn4 module for FRADE')
parser.add_argument('--server', '-s', action='store', dest='serverip', required=True, help='Server to monitor.')
parser.add_argument('--eth', '-e', action='store', dest='eth', required=True, help='Network interface to monitor (e.g., eth4).')
parser.add_argument('--conf', '-c', action='store', dest='conffile', required=True, help='Configuration file with thresholds.')

args = parser.parse_args()


if __name__ == "__main__":
	
# Arguments (again, being bad with globals)                                    


        #WINDOWS=1000 10000 60000 300000 600000
        p1 = re.compile('WINDOWS')
        #DYN_CONF_FILE=conf/wikipedia/dyn.conf
        p2 = re.compile('DYN_CONF_FILE')
        
        try:
                f = open(args.conffile, "r")
        except IOError:
                print("Could not read configuration file: %s" % (args.conffile))
                exit()

        index = args.conffile.rfind("/")
        if (index == -1):
                path = "./"
        else:
                path = args.conffile[0:index+1]
        serverip=args.serverip
        for line in f.readlines():
                line = line.rstrip()
                if (p1.match(line)):
                        winline = line.split('=')[1]
                        winSizes = winline.split(' ')
                        numWin = len(winSizes)
                        for i in xrange(0,numWin):
                                winSizes[i] = int(winSizes[i]);
                        print "Windows ", winSizes, " numWin ", numWin
                elif(p2.match(line)):
                        dynfile = path + line.split('=')[1]
                        try:
                                df = open(dynfile, "r")
                        except IOError:
                                print("Could not read dynamics model configuration file: %s" % (dynfile))
                                exit()
                        for i in xrange(0,3):
                                df.readline()
                        dline = df.readline().rstrip()
                        thresholds = dline.split(' ')
                        print "Thresholds ", thresholds

        p = Popen(["tcpdump", "-i",args.eth,"-n", "-tt" ,"port", "80", "-s", "68"], stdout=PIPE, bufsize=1)
        #p = Popen(["tcpdump", "-r","/zfs/FRADE/log.flood.wikipedia.100.1.dyn4","-nn", "-tt" ,"port", "80", "-s", "68"], stdout=PIPE, bufsize=1)
	with p.stdout:
		for line in iter(p.stdout.readline, b''):
			#Format: "1486008562.808828 IP 10.1.1.13.47661 > 10.1.1.3.80: Flags [S], seq 3937307324, win 29200, options [mss 1460,sackOK,TS[|tcp]>"
			sl  = line.split(" ")

			#print sl
			try:
				timeinmilli,sipport,dipport = float(sl[0])*1000 , sl[2], sl[4]
				dip = ".".join(dipport.split(".")[0:-1])
                                sport = int(sipport.split(".")[-1])
				sip = ".".join(sipport.split(".")[0:-1])
                                flags = sl[6]
                                seq = sl[8]
			except:
				continue
                        if dip == serverip:
                                if (flags == "[S],"):
                                        longip = ip2long(sip)
                                        dyn4(timeinmilli, longip,sport,seq)
				



	p.wait() # wait for the subprocess to exit

	'''
	with open("tcpdumpfile","r") as f:
		for line in f:
			#print line
			sl  = line.split(" ")
                        timeinmilli,ipport = float(sl[0])*1000 , sl[2]
			try:
                        	port = int(ipport.split(".")[-1])
                        	ip = ".".join(ipport.split(".")[0:-1])
			except:
				continue
                        if ip == serverip:
                                continue
                        longip = ip2long(ip)
                        dyn4(timeinmilli, longip,port)
 
	'''
