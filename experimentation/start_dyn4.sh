SERVERIP=`ifconfig | grep 'inet addr:10.' | awk -F':'  '{print $2}' | awk '{print $1}'`
echo "ServerIP $SERVERIP"
cd ../../brandon/FRADE
sudo /usr/bin/python dyn4/dyn4.py -s $SERVERIP -c conf/$1/FRADE100.conf &> /proj/FRADE/output_dyn4 &
sudo /usr/bin/python dyn4/bldyn4.py &> /proj/FRADE/output_dyn4blacklist &
