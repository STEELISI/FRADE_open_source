#!/usr/bin/env bash

USAGE="$0 DIROFLOGS ORIGLOG\n DIROFLOGS should ONLY include:\n\
	\tthe replay apache log (-access.log)\n\
	\tthe -log.txt -events.txt and -sessions.txt created by legitimate.py\n\
	ORIGLOG should be the original log file we extract sessions from."

if [ $# -ne 2 ]; then
	echo "Not enough arguments given."
	echo -e $USAGE
fi

logdir=$1

replay_apache_logs=`ls $logdir/*-access.log | head -1`
orig_apache_logs=$2
extracted_sessions=`ls $logdir/*-sessions.txt | head -1`
origip_to_replayip=`ls $logdir/*-log.txt | head -1`
replay_events=`ls $logdir/*-events.txt | head -1`

# First compare what we extrated to the original logs.
# So we compare -sessions.txt to orig.
echo "Comparing the sessions extracted ($extracted_sessions) to original apache logs ($orig_apache_logs)"
cat $orig_apache_logs | awk '{print $1}' | sort | uniq | while read origip; do 
	echo "Check session for: $origip"
	ocount=`cat $orig_apache_logs | grep -w "$origip" | wc`
	scount=`cat 
done

