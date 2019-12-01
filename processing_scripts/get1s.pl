# One arg file to process
my $fh = new IO::File($ARGV[0]);
$start = 0;
$atstart = 0;
$defense = 0;
while(<$fh>)
{
    @items = split /\s/, $_;
    #0 1501976119 203 0 0 0 0.997106630541872
    $time = $items[0];
    $dur = $items[6];
    $sum = ($items[2]+$items[3]);
    if ($sum > 0)
    {
	$served = $items[2]/$sum;
    }
    else
    {
	$served = 0;
    }
    print "$time $served $dur\n";
    $avg = $avg*0.5+$dur*0.5;
    if ($avg < 1 && $start == 0 && $served > 0.9)
    {
	# Leg traffic has stabilized
	$start = $time;
    }
    elsif($avg > 1 && $start > 0 && $atstart == 0)
    {
	# Attack started
	$atstart = $time;
    }
    elsif($avg < 1 && $atstart > 0 && $served > 0.9)
    {
	# Attack started
	$defense = $time;
	$diff = $defense - $atstart;
	print "Defense $defense atstart $atstart diff $diff\n";
	last;
    }

}

