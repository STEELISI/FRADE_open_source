SERVERIP=`ifconfig | grep 'inet addr:10.' | awk -F':'  '{print $2}' | awk '{print $1}'`
ETH=`perl find_eth.pl`
echo "ServerIP $SERVERIP eth $ETH"
sudo /usr/bin/python dyn4/bldyn4.py &> /proj/FRADE/output_dyn4blacklist &
sleep 1
sudo /usr/bin/python dyn4/dyn4.py -s $SERVERIP -e $ETH -c conf/$1/FRADE100.conf &> /proj/FRADE/output_dyn4 &
