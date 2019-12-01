. ../../config
sudo iptables -F
sudo ipset -X blacklist
#ETH=`perl $path_to_execute_from/brandon/FRADE/find_eth.pl`
#sudo nohup /usr/sbin/tcpdump -i $ETH -nn -w /mnt/log.$1 ip
sudo nohup /usr/sbin/tcpdump -i enp6s0f0 -nn -w /mnt/log.proxy ip
sudo nohup /usr/sbin/tcpdump -i enp6s0f1 -nn -w /mnt/log.$1 ip
