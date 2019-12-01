#!/usr/local/bin//bash
# This one assumes maximum rate and just asking for one main file
# leg client is assumed to be attacker-0 and the rest are attackers
. ../../config
EXP="wiki-testing"
DURATION=300
INT=100

# Args target-server IPs-per-attacker num-attackers module1..modulen
# Example: bash runall.sh wikipedia 1 1 dyn1 dyn2 sem
j=1
modules="-f \\\"-c conf/$1/FRADE100.conf"
ms=""
m4=""
for i do
  if [ $j -ge 4 ] ; then
      echo "Module on " "$i"
      if [ "$i" == "dyn4" ] ; then
	  m4="\"-d $1\""
      else
	  modules="$modules -m $i"
      fi
      ms="$ms$i"
  fi
  j=$(($j+1))
done
modules="$modules\\\""
echo $modules $m4    

echo "Starting logging"
ssh  -o StrictHostKeyChecking=no $1.$EXP.frade "cd $path_to_execute_from/experiments/run/; sudo bash start_log.sh flood.$1.$2.$3.$ms" &
ssh -o StrictHostKeyChecking=no  attacker0.$EXP.frade "cd $path_to_execute_from/experiments/run/; sudo bash start_log.sh legitimate.$1.$2.$3.$ms" &
echo "Restart Web server"
ssh  -o StrictHostKeyChecking=no $1.$EXP.frade "cd $path_to_execute_from/experiments/run/; sudo bash restart_server.sh" &
echo "Starting detector and it will start defenses, if any"
cmd="cd $path_to_execute_from/experiments/run; sudo bash start_detector.sh $modules $m4"
echo $cmd
ssh  -o StrictHostKeyChecking=no $1.$EXP.frade "$cmd" &
sleep 15
echo "Starting leg traffic"
ssh -o StrictHostKeyChecking=no  attacker0.$EXP.frade "sudo python3.4 $path_to_execute_from/traffic/smart_attacker/legitimate.py -s $1 --sessions 100 --logs /proj/FRADE/MTurk/Normalized-logs/$1-new.log &" &
echo "Sleeping"
sleep $INT
j=1
while [ $j -le $3 ] ; do
      echo "Starting attack on attacker$j"
      ssh -o StrictHostKeyChecking=no  attacker$j.$EXP.frade "cd $path_to_execute_from/traffic/flood_attacker/; sudo python3 attack.py -s $1 -n $2 -u ../urls/urls-$1.txt & " &
      j=$(($j+1))
done
sleep $DURATION
j=1
while [ $j -le $3 ] ; do
      echo "Stopping attack on attacker$j"
      ssh -o StrictHostKeyChecking=no  attacker$j.$EXP.frade "sudo pkill -9 python3"
      j=$(($j+1))
done    
sleep $INT
echo "Stopping legitimate traffic"
ssh -o StrictHostKeyChecking=no  attacker0.$EXP.frade "sudo killall python3.4"
echo "Stopping detector"
ssh  -o StrictHostKeyChecking=no $1.$EXP.frade "sudo pkill -9 python"
echo "Saving blacklist"
ssh  -o StrictHostKeyChecking=no $1.$EXP.frade "sudo ipset list blacklist > ~/blacklist.$1.$2.$3.$ms; sudo cp ~/blacklist.$1.$2.$3.$ms; /mnt/blacklist.$1.$2.$3.$ms;"
echo "Stopping logging"
ssh  -o StrictHostKeyChecking=no $1.$EXP.frade "sudo pkill -9 tcpdump"
ssh  -o StrictHostKeyChecking=no attacker0.$EXP.frade "sudo pkill -9 tcpdump"
