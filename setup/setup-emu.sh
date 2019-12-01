# provide two arguments - server name, experiment name before testing like wikipedia wiki
# setup routes
. ../../config
bash assignlegitimate
bash assignattackers
ssh $1.$experiment_name.frade "bash $path_to_execute_from/experiments/setup/setup_victim-emu.sh $experiment_name $path_to_execute_from"
# setup attackers
ssh attacker0.$experiment_name.frade "sudo apt-get update;sudo apt-get install python3-pip;sudo apparmor_parser -R /etc/apparmor.d/usr.sbin.tcpdump; sudo pip3 install netifaces;sudo pip3 install python-dateutil;sudo pip3 install shove"
i=1
while [ $i -le $last_attacker_node ] ; do
    echo "SETTING UP ATTACKER $i"
    ssh attacker$i.$experiment_name.frade "cd $path_to_execute_from/traffic/smart_attacker; sudo bash install" > /dev/null
    ssh attacker$i.$experiment_name.frade "cd $path_to_execute_from/traffic/flood_attacker; sudo bash install" > /dev/null
    i=$(($i+1))
done
bash tune-all.sh $1
