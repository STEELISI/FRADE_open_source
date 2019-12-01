#!/bin/bash
#==============================================================#
#========How to run============================================#
# ./train.sh <server name> <path to training data>
# Example: ./train.sh imgur /proj/FRADE/MTurk/imgur/usenix2/apache2/Filtered-access.log
#==============================================================#

server=$1
train_data_path=$2
##========Training========##
cp $train_data_path logs/$server
sleep 2
python splitlogs.py $server
sleep 2
python sortuserlogs.py $server
sleep 2
python buildModels.py conf/$server/FRADE.conf "findGoodLogs()"
sleep 2
python buildModels.py conf/$server/FRADE.conf "buildModels()"
sleep 2
echo "Last Step"
python dyn2build.py $server
