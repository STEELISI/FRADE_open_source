#!/usr/local/bin//bash
# This one assumes maximum rate and just asking for one main file
# leg client is assumed to be attacker-0 and the rest are attackers
. ../../config
EXP=$experiment_name
DURATION=540
INT=25

# Args target-server IPs-per-attacker num-attackers module1..modulen
# Example: bash runall.sh wikipedia 1 1 dyn1 dyn2 sem
#bash runall-emu.sh imgur 1 1 dyn1
homepage=""
if [ "$1" == "imgur" ]; then
  #homepage=/gallery/AjH07/
  homepage=/abc/index.html
  #homepage=/gallery/nD9RXl/
  #homepage=/gallery/
  #homepage=/gallery/0DsUyr
  #homepage=/yFErLfIb.jpg
  #homepage=/gallery/
fi
if [ "$1" == "wikipedia" ]; then
  homepage=/gallery/kdsTl/
  #homepage=/mediawiki/index.php/Main_Page
  #homepage=/mediawiki/index4.php/Cash_Forecast
  #homepage=/mediawiki/resources/assets/poweredby_mediawiki_176x62.png
  #homepage=/mediawiki/index.php/United_States_presidential_election,_2016
  #homepage=/mediawiki/resources/assets/poweredby_mediawiki_132x47.png
fi
if [ "$1" == "reddit" ]; then
  homepage=/gallery/kdsTl/
  #homepage=/gallery/
  #homepage=/dum.png
  #madeup
  #homepage=/gallery/AjH08/
  #homepage=/mediawiki/index.php/Main_Page
  #homepage=/mediawiki/index.php/Main_Page
  #homepage=/r/showerthoughts/comments/29/my_entire_saturday_if_often_determined_by_whether/
  #homepage=/r/showerthoughts/comments/45/we_should_start_referring_to_handjobs_as_protein/
  #homepage=/r/
  #homepage=/r/showerthoughts/
  #homepage=/subreddits/ 
  #homepage=/static/dummy.html
  #homepage=/static/sprite-reddit.VHIxgRYQgk8.png
  #homepage=/r/showerthoughts/comments/s/allhuman_staff_will_eventually_become_a_selling/.rss
fi
j=1
modules="-f \\\"-c conf/$1/FRADE100.conf -l $log_file"
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

j=1
while [ $j -le $last_attacker_node ] ; do
      ssh -o StrictHostKeyChecking=no  attacker$j.$EXP.frade "sudo rm addresses$j.txt" &
    j=$(($j+1))
done


 
j=1
while [ $j -le $3 ] ; do
      ssh -o StrictHostKeyChecking=no  attacker$j.$EXP.frade "cd $path_to_execute_from/experiments/run/; sudo bash getips.sh | head -$2 > addresses$j.txt; sleep 2; cat addresses$j.txt"
    j=$(($j+1))
done

echo "Starting logging"
ssh  -o StrictHostKeyChecking=no $1.$EXP.frade "cd $path_to_execute_from/brandon/FRADE;sudo ./clean.sh ;cd $path_to_execute_from/experiments/run/; sudo bash start_log.sh flood.$1.$2.$3.$ms" &
#ssh -o StrictHostKeyChecking=no  attacker0.$EXP.frade "cd $path_to_execute_from/experiments/run/; sudo bash start_log.sh legitimate.$1.$2.$3.$ms" &
echo "Restart Web server"
ssh  -o StrictHostKeyChecking=no $1.$EXP.frade "cd $path_to_execute_from/experiments/run/; sudo bash restart_server.sh" &
echo "Starting detector and it will start defenses, if any"
cmd="cd $path_to_execute_from/experiments/run; sudo bash start_detector.sh $modules $m4"
echo $cmd
ssh  -o StrictHostKeyChecking=no $1.$EXP.frade "$cmd" &
sleep 15
echo "Starting leg traffic"
ssh -o StrictHostKeyChecking=no  attacker0.$EXP.frade "sudo python3.4 $path_to_execute_from/traffic/smart_attacker/legitimate.py -s $1 --sessions 80 --logs /proj/FRADE/MTurk/Normalized-logs/$1-new-sorted-only-200s.log &" &
#--debug_log /tmp/leglogs/
echo "Sleeping"
sleep $INT
j=1
while [ $j -le $3 ] ; do
      echo "Starting attack on attacker$j $2 $3"
      #ssh -o StrictHostKeyChecking=no  attacker$j.$EXP.frade "cd $path_to_execute_from/traffic/flood_attacker/; sudo python3 attack.py -s $1 -n $2 -u ../urls/urls-$1.txt & " &
      ####ssh -o StrictHostKeyChecking=no  attacker$j.$EXP.frade "cd $path_to_execute_from/experiments/run/;sudo httperf --server=$1 --uri=$homepage --num-conns=1200000 --rate=1000 --timeout=2 --multiaddress=addresses$j.txt --hog" &
      ssh -o StrictHostKeyChecking=no  attacker$j.$EXP.frade " cd /mnt/attack-tools/hulk; sudo python hulk.py http://10.1.1.2/gallery/abc " &
      j=$(($j+1))
done
sleep $DURATION
j=1
while [ $j -le $3 ] ; do
      echo "Stopping attack on attacker$j"
      ssh -o StrictHostKeyChecking=no  attacker$j.$EXP.frade "sudo pkill -9 httperf; sudo pkill -9 python3; sudo pkill -9 tcpdump ; sudo pkill -9 python"
      j=$(($j+1))
done    
sleep $INT
echo "Stopping legitimate traffic"
ssh -o StrictHostKeyChecking=no  attacker0.$EXP.frade "sudo killall python3.4; sudo pkill -9 python"
echo "Stopping detector"
ssh  -o StrictHostKeyChecking=no $1.$EXP.frade "sudo pkill -9 python"
echo "Saving blacklist"
ssh  -o StrictHostKeyChecking=no $1.$EXP.frade "sudo ipset list blacklist > ~/blacklist.$1.$2.$3.$ms; sudo cp ~/blacklist.$1.$2.$3.$msi /mnt/blacklist.$1.$2.$3.$ms;"
echo "Stopping logging"
ssh  -o StrictHostKeyChecking=no $1.$EXP.frade "sudo pkill -9 tcpdump"
ssh  -o StrictHostKeyChecking=no attacker0.$EXP.frade "sudo pkill -9 tcpdump"
