sleep 3
pkill -9 node
echo "TAB OFF, FRADE ON" > /var/www/html/nobotco/demo/SENSS/Client/TAB.txt
#ssh -o StrictHostKeyChecking=no  attacker0.$EXP.frade "sudo killall python3; sudo pkill -9 python" &
#ssh -o StrictHostKeyChecking=no  attacker0.$EXP.frade "sudo python3 /users/rajat19/frade/traffic/smart_attacker/legitimate.py -s $1 --sessions 200 --logs /proj/FRADE/MTurk/Normalized-logs/proxy-new-sorted-only-200s.log  --interface enp6s0f1 &" &
nodejs /mnt/http-proxy-middleware/examples/express/app1.js >> /mnt/access1.log &
