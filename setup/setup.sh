# provide two arguments - server name, experiment name before testing like wikipedia wiki
# setup routes
bash assignlegitimate $2
bash assignattackers $2
ssh $1.$2-testing.frade "bash ~/frade/experiments/setup/setup_victim.sh $2"
# setup attackers
ssh attacker0.$2-testing.frade "sudo apparmor_parser -R /etc/apparmor.d/usr.sbin.tcpdump"
ssh attacker0.$2-testing.frade "sudo mkdir /zfs; sudo mkdir /zfs/FRADE; sudo mount -t nfs -o tcp,vers=3 zfs:/zfs/FRADE /zfs/FRADE"
i=0
while [ $i -le 15 ] ; do
    echo "SETTING UP ATTACKER $i"
    ssh attacker$i.$2-testing.frade "cd ~/frade/traffic/smart_attacker; sudo bash install" > /dev/null
    ssh attacker$i.$2-testing.frade "cd ~/frade/traffic/flood_attacker; sudo bash install" > /dev/null
    i=$(($i+1))
done
