. ../../config
pkill -9 rsyslog
pkill -9 python
rm /tmp/blacklistpipe
echo "\nExecuting FRADE\n"
iptables -F
ipset -X blacklist
args="$*"
echo $args
cd $path_to_execute_from/brandon/FRADE
./rsyslog $args 2>&1> /proj/FRADE/output_rsys &
/usr/bin/python blacklistd.py 2>&1> /proj/FRADE/output_blacklistd &
