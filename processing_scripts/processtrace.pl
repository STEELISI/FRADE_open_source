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
while ( <TD> )
{
    my @items = split /\s/, $_;
    $time = $items[0];
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
    my @elems = split /\:/, $seq;
    if ($#elems == 1)
    {
	$seq = $elems[1];
	$len = $elems[1] - $elems[0];
    }
    $type = 0;
    $att = 0;
#1485590795.947825 IP 10.1.1.7.41460 > 10.1.1.3.80: Flags [S], seq 2570442519, win 29200, options [mss 1460,sackOK,TS val 208702072 ecr 0,nop,wscale 7], length 0
#1485590795.947854 IP 10.1.1.3.80 > 10.1.1.7.41460: Flags [R.], seq 0, ack 2570442520, win 0, length 0
#1485590796.961308 IP 10.1.1.7.41461 > 10.1.1.3.80: Flags [P.], seq 1:139, ack 1, win 229, options [nop,nop,TS val 208702325 ecr 209664937], length 138
    $l = scalar(keys %{$conns{0}});
    $a = scalar(keys %{$conns{1}});
    if ($time - $lasttime > 1)
    {
	$d = $time - $start;
	$ld = $l - $ll;
	$ad = $a - $la;
	@ls = split /\s/, processstats(0, $time);
	@as = split /\s/, processstats(1, $time);
	$lsd = $ls[0] - $ols;
	$lid = $ls[1] - $oli;
	$asd = $as[0] - $oas;
	$aid = $as[1] - $oai;
	$ols = $ls[0];
	$oli = $ls[1];
	$oas = $as[0];
	$oai = $as[1];
	$cs = scalar(keys %srcs);
	print "$d Conns leg $l att $a diff $ld $ad successful $ls[0] $ls[1] $as[0] $as[1] $ls[2] sources $cs\n";
	$lasttime = $time;
	$ll = $l;
	$la = $a;
    }
    if ($src =~ /\.80$/)
    {
	$type = 1;
    }
    else
    {
	@octs = split /\./, $src;
	$srcs{$octs[0] . "." . $octs[1] . "." . $octs[2] . "." . $octs[3]} = 1;
    }
    if($src =~ /10\.2\./ || $dst =~ /10\.2\./)
    {
	$att = 1;
    }
    if ($type == 0)
    {
	if (!exists($conns{$att}{$src}{$dst}))
	{
	    $conns{$att}{$src}{$dst} = new Conn($time);
	    #print "New conn $src $dst at $time attack $att\n";
	}
	if ($flags =~ /S/ && $conns{$att}{$src}{$dst}->{state} eq '')
	{
	    $conns{$att}{$src}{$dst}->{state} = 'SYN';
	    $conns{$att}{$src}{$dst}->{end} = $time;
	}
	elsif($flags =~ /P/ && $conns{$att}{$src}{$dst}->{seq_req} < $seq && ($conns{$att}{$src}{$dst}->{state} eq 'SYNACK' || $conns{$att}{$src}{$dst}->{state} eq 'REQ'))
	{
	    $conns{$att}{$src}{$dst}->{seq_req} = $seq;
	    $conns{$att}{$src}{$dst}->{state} = 'REQ';
	    $conns{$att}{$src}{$dst}->{end} = $time;
	}
	elsif($flags =~ /F/ && $conns{$att}{$src}{$dst}->{state} eq 'RESP') 
	{
	    $conns{$att}{$src}{$dst}->{state} = 'FIN';
	    $conns{$att}{$src}{$dst}->{end} = $time;
	}
    }
    else
    {
	if (!exists($conns{$att}{$dst}{$src}))
	{
	    $conns{$att}{$dst}{$src} = new Conn($time);
	    #print "New conn $dst $src at $time attack $att R\n";
	}
	if ($flags =~ /S/ && ($conns{$att}{$dst}{$src}->{state} eq '' || $conns{$att}{$dst}{$src}->{state} eq 'SYN'))
	{
	    $conns{$att}{$dst}{$src}->{state} = 'SYNACK';
	    $conns{$att}{$dst}{$src}->{end} = $time;
	}
	elsif($flags =~ /P/ && $conns{$att}{$dst}{$src}->{seq_resp} < $seq && ($conns{$att}{$dst}{$src}->{state} eq 'SYNACK' || $conns{$att}{$dst}{$src}->{state} eq 'REQ' || $conns{$att}{$dst}{$src}->{state} eq 'RESP'))
	{
	    $conns{$att}{$dst}{$src}->{seq_resp} = $seq;
	    $conns{$att}{$dst}{$src}->{state} = 'RESP';
	    $conns{$att}{$dst}{$src}->{end} = $time;
	}
	elsif($flags =~ /F/ && $conns{$att}{$dst}{$src}->{state} eq 'RESP') 
	{
	    $conns{$att}{$dst}{$src}->{state} = 'FIN';
	    $conns{$att}{$dst}{$src}->{state}
	}
	elsif($flags =~ /R/ && $conns{$att}{$dst}{$src}->{state} ne 'FIN' && $conns{$att}{$dst}{$src}->{state} ne 'RESP') 
	{
	    $conns{$att}{$dst}{$src}->{state} = 'RST';
	    $conns{$att}{$dst}{$src}->{end} = $time;
	}
    }
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
		#print "INP: Type $t conn $s $d start $conns{$t}{$s}{$d}->{start} end $conns{$t}{$s}{$d}->{end} time $stime\n";
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
