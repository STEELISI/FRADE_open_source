# two arguments: path to normalized logs and FRADE.conf
$usage="$0 normalized-logs frade-conf type\n";
if ($#ARGV < 2)
{
    print $usage;
    exit;
}
$type = $ARGV[2];
open(my $fh, '<', $ARGV[1])
    or die "Could not open file '$ARGV[1]' $!";
@windows=();
@regex=();
while(<$fh>)
{
    if ($_ =~ /WINDOWS/)
    {
	@items = split /\=/, $_;
	@windows = split /\s+/, $items[1];
    }
    if ($_ =~ /^MAIN/)
    {
	@items = split /\=/, $_;
	@regex = split /\s+/, $items[1];
    }
}
%requests=();
open(my $fh, '<', $ARGV[0])
    or die "Could not open file '$ARGV[1]' $!";

$count=0;
while(<$fh>)
{
#23.112.114.15 1492471058459 GET /mediawiki/ HTTP/1.1 301 193626
#23.112.114.15 1492471058801 GET /mediawiki/index.php/Main_Page HTTP/1.1 200 86414
    @items = split /\s/, $_;
    $ip = $items[0];
    $time = $items[1];
    $url = $items[3];
    $code = int($items[5]);
    if ($code == 301 && $type ne "all")
    {
	next;
    }
    if ($type eq "main")
    {
	$found = 0;
	for $r (@regex)
	{
	    if ($url =~ /$r/)
	    {
		#print "$ip $url \n";
                print "$ip $time $items[2] $url $items[4] $code \n";
                $count++;
		$found = 1;
	    }
	}
	if ($type eq "main")
	{
           # print "$ip $time $url $items[4] $code \n";
	    next;
	}
	if ($found == 1 && $type eq "embed")
	{
	    next;
	}
    }
    if ($ip !~ /\d+\.\d+\.\d+\.\d+/)
    {
	next;
    }
    push(@{$requests{$ip}}, $time);
}
