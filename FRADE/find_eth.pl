open(FE,"ifconfig |") || die "Failed: $!\n";
$cureth = "";
while ( <FE> )
{
    @items = split /\s+/, $_;
    if ($items[0] =~ /^eth/)
    {
	$cureth = $items[0];
    }
    elsif($_ =~ /inet addr:10\./)
    {
	print $cureth;
	exit;
    }
}
