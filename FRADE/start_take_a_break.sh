#ssh -o StrictHostKeyChecking=no  attacker0.ex.frade "sudo killall python3.4; sudo pkill -9 python" &
pkill -9 node
#ssh -o StrictHostKeyChecking=no  attacker0.$EXP.frade "sudo killall python3; sudo pkill -9 python; sudo pkill -9 python3" &
#ssh -o StrictHostKeyChecking=no  attacker0.$EXP.frade "sudo python3 /users/rajat19/frade/traffic/smart_attacker/legitimate.py -s $1 --sessions 200 --logs /proj/FRADE/MTurk/Normalized-logs/proxy-new-sorted-only-200s-a.log  --interface enp6s0f1 &" &
date +%s
nodejs /mnt/http-proxy-middleware/examples/express/app2.js >> /mnt/access.log &
echo "TAB ON, FRADE ON" > /var/www/html/nobotco/demo/SENSS/Client/TAB.txt
#ssh -o StrictHostKeyChecking=no  attacker0.ex.frade "cd /users/rajat19/frade/brandon/FRADE; bash leg_client_tb.sh" &
##pkill -9 node
##node /mnt/http-proxy-middleware/examples/express/app1.js >> /mnt/access.log &
