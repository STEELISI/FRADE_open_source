rm -rf /var/log/apache2/access.log /var/log/apache2/error.log;
service apache2 restart;
iptables -F INPUT;
ipset -X blacklist;
rm -rf /tmp/blacklistpipe;
rm -rf /tmp/dyn4;
