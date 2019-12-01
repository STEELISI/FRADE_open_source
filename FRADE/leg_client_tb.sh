#!/usr/local/bin/bash
while true
do
i=1
while [ $i -le 2 ] ; do


   random0="$(shuf -i 5-17 -n 1)"
   random="$(shuf -i 2-254 -n 1)"
   wget wikipedia/gallery/hot/viral/page/0/hit.json --bind-address=10.1.$random0.$random &

   random0="$(shuf -i 5-17 -n 1)"
   random="$(shuf -i 2-254 -n 1)"
   wget wikipedia/gallery/PwwDd/  --bind-address=10.1.$random0.$random &

   random0="$(shuf -i 5-17 -n 1)"
   random="$(shuf -i 2-254 -n 1)"
   wget wikipedia/gallery/hot/viral/page/0/hit.json --bind-address=10.1.$random0.$random &

   random0="$(shuf -i 5-17 -n 1)"
   random="$(shuf -i 2-254 -n 1)"
   wget wikipedia/gallery/PupUQ/ --bind-address=10.1.$random0.$random &

   random0="$(shuf -i 5-17 -n 1)"
   random="$(shuf -i 2-254 -n 1)"
   wget wikipedia/gallery/hot/viral/page/0/hit.json --bind-address=10.1.$random0.$random &
   i=$(($i+1))
   rm -rf hit*
   rm -rf index*
done
sleep 10
rm -rf hit*
rm -rf index*
done
