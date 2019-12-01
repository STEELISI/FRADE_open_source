#!/usr/local/bin//bash
# This one assumes maximum rate and just asking for one main file
# leg client is assumed to be attacker-0 and the rest are attackers
. ../../config
EXP=$experiment_name
DURATION=600
INT=70

# Args target-server IPs-per-attacker num-attackers module1..modulen
# Example: bash runall.sh wikipedia 1 1 dyn1 dyn2 sem
#bash runall-emu.sh imgur 1 1 dyn1
homepage=""
if [ "$1" == "imgur" ]; then
  homepage=/gallery/AjH07/
fi
if [ "$1" == "wikipedia" ]; then
  homepage=/mediawiki/index.php/Main_Page
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



 
echo "Starting logging"
ssh  -o StrictHostKeyChecking=no $1.$EXP.frade "cd $path_to_execute_from/brandon/FRADE;sudo ./clean.sh" &
echo "Restart Web server"
ssh  -o StrictHostKeyChecking=no $1.$EXP.frade "cd $path_to_execute_from/experiments/run/; sudo bash restart_server.sh" &
echo "Starting detector and it will start defenses, if any"
cmd="cd $path_to_execute_from/experiments/run; sudo bash start_detector.sh $modules $m4"
echo $cmd
ssh  -o StrictHostKeyChecking=no $1.$EXP.frade "$cmd" &
sleep $INT
sleep $DURATION
echo "Stopping detector"
ssh  -o StrictHostKeyChecking=no $1.$EXP.frade "sudo pkill -9 python"
