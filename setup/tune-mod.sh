#!/usr/bin/env bash

echo "You must be root to run this."
SYSCTL=/sbin/sysctl

MAXCONN=8192

# Increase the number of max file descriptors we can have.
$SYSCTL fs.file-max=5000000
# Tune conn memory
$SYSCTL net.core.rmem_max=33554432
$SYSCTL net.core.wmem_max=33554432
$SYSCTL net.core.wmem_default=33554432
$SYSCTL net.ipv4.tcp_rmem="4096 16384 33554432"
$SYSCTL net.ipv4.tcp_wmem="4096 16384 33554432"
$SYSCTL net.ipv4.tcp_mem="786432 1048576 26777216"
$SYSCTL net.ipv4.tcp_synack_retries=0
$SYSCTL net.ipv4.tcp_syn_retries=0


$SYSCTL net.core.netdev_max_backlog=400000
$SYSCTL net.core.optmem_max=10000000
$SYSCTL net.core.rmem_default=10000000
$SYSCTL net.core.rmem_max=10000000
$SYSCTL net.core.somaxconn=65535
$SYSCTL net.core.wmem_default=10000000
$SYSCTL net.core.wmem_max=10000000
$SYSCTL net.ipv4.conf.all.rp_filter=1
$SYSCTL net.ipv4.conf.default.rp_filter=1
$SYSCTL net.ipv4.ip_local_port_range="1024 65535"
$SYSCTL net.ipv4.tcp_congestion_control=bic
$SYSCTL net.ipv4.tcp_ecn=0
$SYSCTL net.ipv4.tcp_max_syn_backlog=12000
$SYSCTL net.ipv4.tcp_max_tw_buckets=2000000
$SYSCTL net.ipv4.tcp_mem="30000000 30000000 30000000"
$SYSCTL net.ipv4.tcp_rmem="30000000 30000000 30000000"
$SYSCTL net.ipv4.tcp_sack=1
$SYSCTL net.ipv4.tcp_timestamps=1
$SYSCTL net.ipv4.tcp_wmem="30000000 30000000 30000000"
$SYSCTL net.ipv4.tcp_tw_reuse=1
$SYSCTL net.ipv4.tcp_tw_recycle=1
##Extra
$SYSCTL kernel.shmmni=5000000
$SYSCTL net.ipv4.tcp_fin_timeout=5
$SYSCTL net.ipv4.tcp_dsack=0
$SYSCTL net.ipv4.tcp_sack=0
$SYSCTL net.ipv4.tcp_max_orphans=375536
$SYSCTL net.ipv4.tcp_no_metrics_save=1
$SYSCTL net.ipv4.tcp_tw_recycle=0
$SYSCTL net.ipv4.tcp_tw_reuse=0
$SYSCTL net.ipv4.tcp_orphan_retries=0
$SYSCTL net.ipv4.tcp_fin_timeout=5
$SYSCTL net.netfilter.nf_conntrack_tcp_timeout_close=5
$SYSCTL net.netfilter.nf_conntrack_tcp_timeout_close_wait=5
$SYSCTL net.netfilter.nf_conntrack_tcp_timeout_fin_wait=5
$SYSCTL net.netfilter.nf_conntrack_tcp_timeout_last_ack=5
$SYSCTL net.netfilter.nf_conntrack_tcp_timeout_max_retrans=10
$SYSCTL net.netfilter.nf_conntrack_tcp_timeout_syn_recv=30
$SYSCTL net.netfilter.nf_conntrack_tcp_timeout_syn_sent=30
$SYSCTL net.netfilter.nf_conntrack_tcp_timeout_time_wait=30
$SYSCTL net.netfilter.nf_conntrack_tcp_timeout_unacknowledged=45





$SYSCTL net.core.dev_weight=600
IF=`perl getif`
ifconfig $IF txqueuelen 1000


$SYSCTL net.ipv4.tcp_max_syn_backlog=`let x=$MAXCONN*10; echo $x`
# This is backlog of connections *per* port. Set apache's 
# ListenBacklog to just under this value:
#$SYSCTL net.core.somaxconn=${MAXCONN}
$SYSCTL net.ipv4.tcp_syncookies=1
#$SYSCTL net.ipv4.netfilter.ip_conntrack_tcp_timeout_time_wait = 1


# Specificically for Client-side 
$SYSCTL net.ipv4.ip_local_port_range="900    65535"
echo 3000000 > /proc/sys/fs/nr_open
ulimit -n 2000000
echo 1 > /proc/sys/net/ipv4/tcp_tw_recycle


# For ARP cache
# The minimum number of entries to keep in the ARP cache.
$SYSCTL net.ipv4.neigh.default.gc_thresh1=4096
# The soft maximum number of entries to keep in the ARP cache. 
$SYSCTL net.ipv4.neigh.default.gc_thresh2=8192 
# The hard maximum number of entries to keep in the ARP cache. 
$SYSCTL net.ipv4.neigh.default.gc_thresh3=16384
# How often the ARP cache is cleared
$SYSCTL net.ipv4.neigh.default.gc_interval=60





