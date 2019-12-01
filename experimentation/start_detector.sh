. ../../config
SERVERIP=`ifconfig | grep 'inet addr:10.' | awk -F':'  '{print $2}' | awk '{print $1}'`
ETH=`perl $path_to_execute_from/brandon/FRADE/find_eth.pl`
echo "ServerIP $SERVERIP eth $ETH"
args="$*"
cd $path_to_execute_from/brandon/FRADE
#cmd="sudo /usr/bin/python3 detector.py -i $SERVERIP -n $ETH $args > /tmp/det"
echo "TAB OFF, FRADE OFF" > /var/www/html/nobotco/demo/SENSS/Client/TAB.txt
cmd="sudo /usr/bin/python3 detector.py -i 10.1.1.2 -n enp6s0f0 $args > /tmp/det"
echo $cmd
echo $cmd>/tmp/runfile
chmod a+rx /tmp/runfile
exec /tmp/runfile
