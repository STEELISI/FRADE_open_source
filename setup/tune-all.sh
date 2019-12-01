# One arg - server name
. ../../config

echo "$1"
sleep 5
i=0
while [ $i -le $last_attacker_node ] ; do
  ssh attacker$i.$experiment_name.frade "cd $path_to_execute_from/experiments/setup/; sudo $path_to_execute_from/experiments/setup/tune-test.sh"
  i=$(($i+1))
done
ssh $1.$experiment_name.frade "cd $path_to_execute_from/experiments/setup/; sudo $path_to_execute_from/experiments/setup/tune-test.sh"
