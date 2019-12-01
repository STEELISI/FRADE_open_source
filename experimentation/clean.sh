rm /tmp/blacklistpipe
iptables -F
ipset -X blacklist
rm /var/log/apache2/access.log
sudo service nginx restart
