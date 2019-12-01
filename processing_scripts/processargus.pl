# One argument file name with argus records

if ($#ARGV < 0)
{
    print "$usage\n";
    exit;
}
%times=();
%flows=();
%durs=();
%succ=();
%fail=();
open(RA,"ra -r $ARGV[0] -u -Zb -s +startime lasttime dur |") || die "Failed: $!\n";
while ( <RA> )
{
    @items = split /\s+/, $_;
    $time = int($items[0]);
    $i = 2;
    $leg = 0;
    if ($items[2] !~ /^10/)
    {
	$i++;
    }
    $src = $items[$i];
    $dst = $items[$i+2];
    $state = $items[$i+7];
    $dur = $items[$i+10];
    if ($dst !~ /^10\.1\.1\.4/)
    {
	next;
    }
    if ($src =~ /^10\.1\.2/)
    {
	$leg = 1;
    }
    if ($state =~  /P/)
    {
	$succ{$time}{$leg}++;
	$durs{$time} += $dur;
	$flows{$time} += 1;
    }
    else
    {
	$fail{$time}{$leg}++;
    }
    $times{$time} = 1;
}
$start = 0;
for $t (sort {$a <=> $b} keys %times)
{
    if ($start == 0)
    {
	$start = $t;
    }
    for $l (0,1)
    {
	if (!exists($succ{$t}{$l}))
	{
	    $succ{$t}{$l} = 0;
	}
	if (!exists($fail{$t}{$l}))
	{
	    $fail{$t}{$l} = 0;
	}
    }
    $diff = $t - $start;
    print "$diff $t ";
    for $l (1,0)
    {
	print "$succ{$t}{$l} $fail{$t}{$l} ";
    }
    if (exists($durs{$t}))
    {
	$r = $durs{$t}/$flows{$t};
	print "$r\n";
    }
    else
    {
	print "0\n";
    }
}
