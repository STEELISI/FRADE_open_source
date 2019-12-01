echo "TRANS ON, TAB OFF,   FRADE OFF" > /var/www/html/nobotco/demo/SENSS/Client/TAB.txt
sleep 10
pkill -9 rsyslog
BLACK=`ps axuw | grep black | awk '{print $2}'`
DYN4=`ps axuw | grep dyn4 | awk '{print $2}'`
for pid in $BLACK $DYN4  ; do
    sudo kill -9 $pid
done
