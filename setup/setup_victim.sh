bash ~/frade/experiments/setup/setuproute $1
sudo apt-get update
sudo apt-get install -y libboost-all-dev ipset
cd ~/frade/brandon/FRADE
make clean; make
sudo apparmor_parser -R /etc/apparmor.d/usr.sbin.tcpdump
sudo mkdir /zfs
sudo mkdir /zfs/FRADE
sudo mount -t nfs -o tcp,vers=3 zfs:/zfs/FRADE /zfs/FRADE
