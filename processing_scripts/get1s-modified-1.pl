# One arg file to process
my $fh = new IO::File($ARGV[0]);
$atstart = 0;
$defense = 0;
$att_sum = 0;
while(<$fh>)
{
    @items = split /\s/, $_;
    #0 1501976119 203 0 0 0 0.997106630541872
    $time = $items[0];
    $dur = $items[6];
    $att_sum = ($items[4]+$items[5]);
    print "$time $dur\n";
    if($att_sum > 0 && $atstart == 0)
    {
	# Attack started
	$atstart = $time;
    }
    elsif( $atstart > 0 && $items[2] > 0 && $items[3] == 0 && $items[4] == 0 && $items[5] > 0)
    {
	# Attack started
	$defense = $time;
	$diff = $defense - $atstart;
	print "Defense $defense atstart $atstart diff $diff\n";
	last;
    }

}

