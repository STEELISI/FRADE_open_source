rm /tmp/blacklistpipe
#rm /tmp/blacklistpipe1
iptables -F
ipset -X blacklist
args="$*"
echo $args
./rsyslog $args 2>&1> /proj/FRADE/output_rsys &
#./rsyslog -c conf/lb/FRADE100.conf -m dyn1 -l /proj/FRADE/accesstrans.log 2>&1> /proj/FRADE/output_rsys1 &
#/usr/bin/python blacklistdtb.py 2>&1> /proj/FRADE/output_blacklistd1 &
/usr/bin/python blacklistd.py 2>&1> /proj/FRADE/output_blacklistd &
#/usr/bin/python blacklistd1.py 2>&1> /proj/FRADE/output_blacklistd1 &
#cd /mnt; /usr/bin/python custom.py &
