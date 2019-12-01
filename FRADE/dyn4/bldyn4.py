import random
import sys
import socket, struct
import subprocess
import thread
import Queue
import time
import os
import errno

blacklisted = {}
SLEEP = 2 
q = Queue.Queue()
PIPE = "/tmp/dyn4"
frade_conf = "conf/imgur/FRADE.conf"
ipsetTIMEOUT = str(300)


# This method should be written corresponding to writer's (to the pipe) method ip2long i.e. big Endian and little endian conversion
def long2ip(longip):
        return socket.inet_ntoa(struct.pack('!L', longip))


def readPipe():
	"""
	This function reads ip from pipe. Checks if it is already there in the blacklisted dictionary.
	If it is not there, it inserts the ip into queue.
	"""
	global blacklisted
	global q
	
	try:
		os.mkfifo(PIPE)
	except OSError as oe:
		if oe.errno != errno.EEXIST:
			raise

	with open(PIPE,"r") as f:
		while True:
			line = f.readline()
			if len(line) != 0:
				ip = line.rstrip("\n")
				longip = long(ip)
				if longip not in blacklisted:
						blacklisted[longip] = ""
						q.put(longip)
						#print "Queued: " + long2ip(longip) + " time: " + str(time.time())

			else:
				time.sleep(SLEEP)
				continue


def blacklist():
	global q

		
	#ipsetcmd = "ipset create blacklist hash:ip timeout "+ ipsetTIMEOUT +" hashsize 1000000 maxelem 1000000"
	try:
		ipsetcmd = "ipset create blacklist hash:ip hashsize 1000000 maxelem 1000000 -exist"
        	run_ipsetcmd = subprocess.check_output(ipsetcmd,shell=True)
	except:
		print "Blacklist set has already been created!"

	try:
        	cmd = "iptables -A INPUT -m set --match-set blacklist src -j DROP"
        	result = subprocess.check_output(cmd, shell=True)
	except:
		print "iptables rule has already been inserted!"


	while True:
		if q.empty():
			time.sleep(1)
		else:
			longip = q.get()
			ip = long2ip(longip)
			try:
				cmd = "ipset add blacklist " + ip # + " -exist"##cmd = "iptables -A INPUT -s " + ip + " -j DROP"
				result = subprocess.check_output(cmd, shell=True)
				print "blacklisted: " + ip + " time: " + str(time.time())
				sys.stdout.flush()
			except:
				#raise ValueError("failed to include " + ip + " into iptables!!")
				print "ip is already blacklisted!!"


if __name__ == "__main__":

	try:
		thread.start_new_thread(readPipe,())
		thread.start_new_thread(blacklist,())
	except:
		print "Error: Unable to start thread"

	while 1:
		pass
					

