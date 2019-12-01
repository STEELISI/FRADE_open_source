
******* How to set up Frade for a particular server and how to run individual modules ******

REQUIREMENTS:
1) Make sure that the server is setup to give following access log formats:
IMGUR and WIKIPEDIA : <IP> <TIME MILLISECONDS> <METHOD> <URI> <HTTP-VERSION> <STATUS CODE> <PROCESSING TIME in microseconds>
REDDIT : PREFIX : "<IP> <TIME SECONDS> <METHOD> <URI> <HTTP-VERSION> <STATUS CODE> <PROCESSING TIME in milliseconds>"
	 example of reddit : May  7 18:00:35 localhost haproxy[26252]: "155.98.38.135 1494201635 GET / HTTP/1.1 200 207"
for imgur and wikipedia, you can refer to /proj/FRADE/frade_git/brandon/FRADE/apacheconf_imgur example file to see what directive to use to achieve abve format.
For reddit, I think Rajat knows coz when he set up the server, we got the required format
  

PATH := /proj/FRADE/frade_git/brandon/FRADE/
Important Files: PATH/rsyslog.cpp, PATH/FRADE.cpp

1)
Process starts with rsyslog.cpp. It performs two tasks. Firstly, it initializes the FRADE object with server's configuration file and secondly, it 
continuously reads from the accesslog file and calls beAFRADE method on that object, passing values extracted from the access log line as parameters. 

2)
What we need to change in rsyslog.cpp is the line #define CONFIG_FILE "conf/imgur/FRADE.conf" in rsyslog.cpp file according to server. For example, if we are running 
for wikipedia then the line would be #define CONFIG_FILE "conf/wikipedia/FRADE.conf" and the same goes for reddit as well. 
There is one more variable that you can control and that is batchsize in rsyslog.cpp. 
To handle out of order request, we do batch processing. The size of the batch is decided by this variable.
Now, the flow goes to FRADE.cpp as the rsyslog.cpp calls beAFRADE method on each of the access.log file line.

3)
The process starts with beAFRADE function. The flow is very easy to understand. The function firsts try to fetch the user record based on user IP if it already 
exists, otherwise initializes a new one.

4)
After that, the first detection module that will be called is deception. In beAFRADE function there is an if block for this. (marked as /*-----Deception Start---*/) If 
we do not want to test deception, we comment out this if block. To test deception for different servers, uncomment corresponding two variables apache_doc_root
and deceptionfile in the beginning of FRADE.cpp. If you set up the servers again (possibly in case of reddit), pls double check if both the paths are correct.

5)
If request comes out of deception as benign, we do further processing on it. There is one if-else block for this. If it is a main request, then if block gets 
executed and else block gets executed otherwise. 
If it is a main request, we first check dynamics 1 and 3 and then semantics. If we do not want to test dynamics 1 and 3 then we comment out corresponding if 
block ( if(dynamics1and3(arguments)) ). The same goes for semantics. 
If it is an embedded obj request, dyn2 will be executed. If we do not want to test it, we comment the corresponding if block ( if(dynamics2(arguments)) ). These 
if blocks are in beAFRADE function only and very easy to find.

6)
dynamics 1 and 3 are combined in a function for simplicity. But, if we only want to test one of them, then just go to the dynamics1and3 function definition and 
remove the corresponding test from if statement where values are checked against threshold values. (if (ud->counts[i] > dyn1Threshes[i] || ud->procs[i] > 
dyn3Threshes[i]) ).


7)
If we do not want to run dyn4 then comment out below lines in start_deception.sh file.
sudo /usr/bin/python dyn4/dyn4.py 2>&1 > /proj/FRADE/output_dyn4 &
sudo /usr/bin/python dyn4/bldyn4.py 2>&1 > /proj/FRADE/output_dyn4blacklist &

8) After making any changes, run make rsyslog command from /proj/FRADE/frade_git/brandon/FRADE/.
I know this is not the ideal way of doing what we are doing. We can make it cleaner if we really need to.

