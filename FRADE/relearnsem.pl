#Two args - normalized logs to learn from and conf file
$usage="$0 normalized-logs frade-conf type\n";
if ($#ARGV < 1)
{
    print $usage;
    exit;
}
$type = $ARGV[2];
open(my $fh, '<', $ARGV[1])
    or die "Could not open file '$ARGV[1]' $!";
@regex=("/*");
while(<$fh>)
{
    #print($_);
    if ($_ =~ /^MAIN/)
    {
            
	    @items = split /\=/, $_;
	@regex = split /\s+/, $items[1];
    }
}
%requests=();
@limits=(1,2,3,4,5,6,7,8,9,10,15,20,25,30,35,40,45,50,1000);
open(my $fh, '<', $ARGV[0])
    or die "Could not open file '$ARGV[1]' $!";
while(<$fh>)
{
#23.112.114.15 1492471058459 GET /mediawiki/ HTTP/1.1 301 193626
#23.112.114.15 1492471058801 GET /mediawiki/index.php/Main_Page HTTP/1.1 200 86414
    @items = split /\s/, $_;
    $ip = $items[0];
    $time = $items[1];
    $url = $items[3];
    $code = int($items[5]);
    if ($code == 301)
    {
	next;
    }
    $found = 0;
    for $r (@regex)
    {   
	if ($url =~ /$r/)
	{
	    $found = 1;
	}
    }
    if (!$found)
    {
	next;
    }
    # This is a main request
    push(@{$requests{$ip}}, $url);
}
#print "Users " . scalar(keys %requests) . "\n";
%transitions = ();
for $ip (keys %requests)
{ 
    $prev = "";
    for $url (@{$requests{$ip}})
    {
	if ($prev ne  "")
	{
	    $transitions{$prev}{$url}++;
	    $transitions{$url}{$prev}++;
	}
	$prev = $url;
    }
}
for $a (keys %transitions)
{
    $sum = 0;
    for $b (keys %{$transitions{$a}})
    {
	$sum += $transitions{$a}{$b};
    }
    for $b (keys %{$transitions{$a}})
    {
	$transitions{$a}{$b} /= $sum;
    }
}
%seqs=();
for $ip (keys %requests)
{
    $l = 0;
    $p = 1;
    $prev = "";
    for $url (@{$requests{$ip}})
    {
	if ($prev ne "")
	{
	    $p = $p*$transitions{$prev}{$url};
	    $y = 0;
	    for $x (@limits)
	    {
		if ($l <= $x)
		{
		    $y = $x;
		    last;
		}
	    }
	    if ($l > 0)
	    {
		push(@{$seqs{$y}}, $p);
	    }
	}
	$l++;
	$prev = $url;
    }
    if ($p < 1)
    {
#	print "IP $ip len $l p $p\n";
    }
}
for $l (sort {$a <=> $b} keys %seqs)
{
    #print "SEQ $l ";
    for $p (sort {$a <=> $b} @{$seqs{$l}})
    {
	#print "$p ";
    }
    #print "\n";
    @sorted = sort {$b <=> $a} @{$seqs{$l}};
    #print "SEQ $l members " . scalar(@sorted) . "\n";
    if ($l <= 50)
    {
#    	print "$sorted[scalar(@sorted)-1] ";
        print "$sorted[int(0.95*(scalar(@sorted)-1))] ";
    }
    else
    {
	print "$sorted[int(0.95*(scalar(@sorted)-1))] ";
    }
}
for $a (keys %transitions)
{
    for $b (keys %{$transitions{$a}})
    {
	print "$a $b $transitions{$a}{$b} True True\n";
    }
}
