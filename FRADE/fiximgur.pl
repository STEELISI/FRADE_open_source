# One arg - sem conf for imgur
$fh = new IO::File($ARGV[0]);
<$fh>;
<$fh>;
%transitions = ();
%added = ();
%files = ();
while(<$fh>)
{
    @items = split /\s+/, $_;
    
    $transitions{$items[0]}{$items[1]} = $items[2];
}
for $a (keys %transitions)
{
    for $b (keys %{$transitions{$a}})
    {
	if (!exists($transitions{$b}{$a}))
	{
	    $transitions{$b}{$a} = $transitions{$a}{$b};
	    print "$b $a $transitions{$b}{$a} False False\n";
	}
    }
}
$fh = new IO::File($ARGV[0]);
<$fh>;
<$fh>;
while(<$fh>)
{
    @items = split /\s+/, $_;

    if ($items[0] =~ /(^\/gallery\/\w+\/)(.*)/)
    {
	$folder1 = $1;
    }
    else
    {
	$folder1 = $items[0];
    }

    if ($items[1] =~ /(^\/gallery\/\w+\/)(.*)/)
    {
	$folder2 = $1;
    }
    else
    {
	$folder2 = $items[1];
    }
    if (!exists($transitions{$folder1}{$folder2}) && !exists($transitions{$folder2}{$folder1}))
    {
	$added{$folder1}{$folder2} += $items[2];
    }
}
for $a (keys %added)
{
    $sum = 0;
    for $b (keys %{$added{$a}})
    {
	$sum += $added{$a}{$b};
    }
    for $b (keys %{$added{$a}})
    {
	$added{$a}{$b} /= $sum;
	print "$a $b $added{$a}{$b} False False\n";
    }
}
