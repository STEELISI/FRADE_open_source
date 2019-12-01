# One arg - server name
. ../../config
i=1
while [ $i -le $last_attacker_node ] ; do
#  ssh attacker$i.$experiment_name.frade "sudo git clone https://github.com/klueska/httperf.git; sleep 20; cd httperf; mkdir build ; sudo autoreconf -i; sleep 20; cd build; sudo ../configure ; sleep 10;sudo  make;sleep 20;sudo  make install"
ssh attacker$i.$experiment_name.frade "cd httperf/build; sudo ../configure ; sleep 10;sudo  make;sleep 20;sudo  make install"
ssh attacker$i.$experiment_name.frade " cd /proj/FRADE/httperf-versions/httperf; sudo make install; sudo make"
  i=$(($i+1))
done
