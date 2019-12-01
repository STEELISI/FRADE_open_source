# One arg - server name
. ../../config
i=1
while [ $i -le $last_attacker_node ] ; do
#  ssh attacker$i.$experiment_name.frade "sudo git clone https://github.com/klueska/httperf.git; sleep 20; cd httperf; mkdir build ; sudo autoreconf -i; sleep 20; cd build; sudo ../configure ; sleep 10;sudo  make;sleep 20;sudo  make install"
ssh attacker$i.$experiment_name.frade "sudo cp -r /proj/FRADE/attack-tools/ /mnt/"
ssh attacker$i.$experiment_name.frade "sudo apt-get update; sudo apt-get install ruby"
  i=$(($i+1))
done
