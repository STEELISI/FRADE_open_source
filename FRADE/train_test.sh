#!/bin/bash
#==============================================================#
#========How to run============================================#
# train_test.sh <server name> <model (dyn1 or dyn2 or dyn3 or sem or dec)> <training-set-version ( 1-old; 2-new; 3-newest)> <training-data-percentage> <testing-set-version ( 1-old; 2-new; 3-newest)> #
# Example: ./train_test.sh imgur dyn1 1 99 1 
#==============================================================#

server=$1
model=$2
train_data=$3
percent=$($(100-$4)*0.01) #check this
test_data=$4
train_path=$server_$train_data
test_path=$server_$test_data
##========Training========##
cp train_path /proj/FRADE/frade_git/brandon/FRADE/logs/$server
<--use code from reddit for %part-->
python splitlogs.py $server
python sortuserlogs.py $server
python buildModels.py conf/$server/FRADE.conf "findGoodLogs()"
python buildModels.py conf/$server/FRADE.conf "buildModels()"

##========Testing========##
cp $model.cpp FRADE.cpp
<Change in rsyslog.cpp conf path and testing path>
./clean.sh
nohup python blacklistd.py &
./rsyslog
sleep 10
ipset list blacklist > out
