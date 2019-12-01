#!/usr/local/bin//bash
# This one assumes maximum rate and just asking for one main file
# leg client is assumed to be attacker-0 and the rest are attackers
. ../../config
EXP=$experiment_name

# Args target-server IPs-per-attacker num-attackers module1..modulen
# Example: bash runall.sh wikipedia 1 1 dyn1 dyn2 sem
#bash killall.sh imgur 1 1 dyn1

j=1
while [ $j -le $3 ] ; do
      echo "Stopping attack on attacker$j"
      ssh -o StrictHostKeyChecking=no  attacker$j.$EXP.frade "sudo pkill -9 httperf; sudo pkill -9 python3; sudo pkill -9 tcpdump ; sudo pkill -9 python ; sudo pkill -9 ruby"
      j=$(($j+1))
done
sleep $INT
echo "Stopping legitimate traffic"
ssh -o StrictHostKeyChecking=no  attacker0.$EXP.frade "sudo killall python3.4; sudo pkill -9 python; sudo pkill -9 bash; sudo pkill -9 wget "
echo "Stopping detector"
ssh  -o StrictHostKeyChecking=no $1.$EXP.frade "sudo pkill -9 python ; sudo pkill -9 rsyslog"
echo "Saving blacklist"
ssh  -o StrictHostKeyChecking=no $1.$EXP.frade "sudo ipset list blacklist > ~/blacklist.$1.$2.$3.$ms; sudo cp ~/blacklist.$1.$2.$3.$msi /mnt/blacklist.$1.$2.$3.$ms;"
echo "Stopping logging"
ssh  -o StrictHostKeyChecking=no $1.$EXP.frade "sudo pkill -9 tcpdump; sudo pkill -9 node"
ssh  -o StrictHostKeyChecking=no attacker0.$EXP.frade "sudo pkill -9 tcpdump"

