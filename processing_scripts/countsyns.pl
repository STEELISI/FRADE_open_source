#!/bin/perl

BEGIN { $| = 1 }

our %conns=();
our %srcs=();
package Conn;
sub new
{
    my $class = shift;
    my $self = {
        state => '',
	req => 0,
	resp => 0,
	seq_req => 0,
	seq_resp => 0,
	start => shift,
	end => start
    };
    bless $self, $class;
    return $self;
}

$usage = "$0 tracefile\n";
if ($#ARGV < 0)
{
    print $usage;
    exit 1;
}
open(TD,"tcpdump -r $ARGV[0] -nn -tt ip |") || die "Failed: $!\n";
$start = 0;
$lasttime = 0;
$ll = 0;
$la = 0;
$ols = 0;
$oli = 0;
$oas = 0;
$oai = 0;
%syns=();
%acks=();
while ( <TD> )
{
    my @items = split /\s/, $_;
    $time = int($items[0]);
    if ($start == 0)
    {
	$start = $time;
	$lasttime = $time;
    }
    $src = $items[2];
    $dst = $items[4];
    $dst =~ s/\://;
    $flags = $items[6];
    $seq = $items[8];
    $len = 0;
    if ($flags =~ /\[S\]/)
    {
	$syns{$time}++;
    }
    elsif ($flags =~ /\[S.\]/)
    {
	$acks{$time}++;
    }
}
for $t (sort {$a <=> $b} keys %syns)
{
    print "$t syns $syns{$t} acks $acks{$t}\n";
}

sub processstats
{
    my ($t, $time) = @_;
    $succ=0;
    $inp=0;
    $stime=0;
    $c=0;
    for $s (keys %{$conns{$t}})
    {
	for $d (keys %{$conns{$t}{$s}})
	{
	    $limit = $time-10;
	    if (int($conns{$t}{$s}{$d}->{start}) >= int($limit))
	    {
		next;
	    }
	    #print "Time $time limit $limit processing conn {$t}{$s}{$d} state $conns{$t}{$s}{$d}->{state} end $conns{$t}{$s}{$d}->{end} \n";

	    if ($conns{$t}{$s}{$d}->{state} eq 'FIN' || $conns{$t}{$s}{$d}->{state} eq 'RESP')
	    {
		$succ++;
		$stime += ($conns{$t}{$s}{$d}->{end} - $conns{$t}{$s}{$d}->{start});
		if ($t == 0)
		{
		    #print "SUCC: Type $t conn $s $d start $conns{$t}{$s}{$d}->{start} end $conns{$t}{$s}{$d}->{end} time $stime\n";
		}
	    }
	    elsif($conns{$t}{$s}{$d}->{state}  ne 'DONE')
	    {
		$inp++;
		if ($t == 1)
		{
		    print "INP: Type $t conn $s $d start $conns{$t}{$s}{$d}->{start} end $conns{$t}{$s}{$d}->{end} time $stime\n";
		}
	    }
	    $conns{$t}{$s}{$d}->{state}='DONE';
	    delete($conns{$t}{$s}{$d});
	}
    }
    if ($succ > 0)
    {
	$stime /= $succ;
    }
    return "$succ $inp $stime";
}
