#!/usr/local/bin//bash
. ../../config
EXP=$experiment_name
DURATION=300

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
  #homepage=/gallery/
  homepage=/mediawiki/index.php/Main_Page
  #homepage=/mediawiki/index4.php/Cash_Forecast
  #homepage=/mediawiki/resources/assets/poweredby_mediawiki_176x62.png
  #homepage=/mediawiki/index.php/United_States_presidential_election,_2016
  #homepage=/mediawiki/resources/assets/poweredby_mediawiki_132x47.png
fi
if [ "$1" == "reddit" ]; then
  homepage=/index.html
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
while [ $j -le $last_attacker_node ] ; do
      ssh -o StrictHostKeyChecking=no  attacker$j.$EXP.frade "sudo rm addresses$j.txt" &
    j=$(($j+1))
done

sleep 10
j=1
while [ $j -le $3 ] ; do
      echo "Starting attack on attacker$j $2 $3"
      #ssh -o StrictHostKeyChecking=no  attacker$j.$EXP.frade "cd $path_to_execute_from/traffic/flood_attacker/; sudo python3 attack.py -s $1 -n $2 -u ../urls/urls-$1.txt & " &
      ssh -o StrictHostKeyChecking=no  attacker$j.$EXP.frade "cd $path_to_execute_from/experiments/run/;sudo httperf --server=$1 --uri=$homepage --num-conns=1000000 --rate=1000 --timeout=3 --multiaddress=addresses$j.txt --hog" &
      ##ssh -o StrictHostKeyChecking=no  attacker$j.$EXP.frade "cd $path_to_execute_from/experiments/run/;sudo httperf --server=$1 --num-conns=1200000 --rate=1000 --timeout=2 --wlist=urls_$1 --multiaddress=addresses$j.txt --hog" &
      j=$(($j+1))
done
sleep $DURATION
