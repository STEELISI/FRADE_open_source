pkill -9 rsyslog
pkill -9 python
rm /tmp/blacklistpipe
iptables -F
ipset -X blacklist
rm /var/log/apache2/access.log
service apache2 restart
