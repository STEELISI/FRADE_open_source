##==##
path_to_execute_from=$2
bash $path_to_execute_from/experiments/setup/setuproute $1
sudo apt-get update
sudo apt-get install -y libboost-all-dev ipset
cd $path_to_execute_from/brandon/FRADE
make clean; make
sudo apparmor_parser -R /etc/apparmor.d/usr.sbin.tcpdump
sudo /usr/testbed/bin/mkextrafs /mnt
