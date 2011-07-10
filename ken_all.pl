use strict;
use utf8;
use Lingua::JA::Moji qw/hw2katakana kata2hira/;
use JSON;

open my $ken_all_csv, '<:encoding(shiftjis)', 'KEN_ALL.CSV'
    or die 'failed to open KEN_ALL.csv';

print "load --table KEN_ALL\n";
print "[";
my $i = 0;
while ( my $record = <$ken_all_csv> ) {
    my ($zip_code, @tmp) = ( split /,/, $record )[2 .. 8];

    foreach my $value ($zip_code, @tmp) {
        $value =~ s/\A "(.*)" \z/$1/xms;
    }

    my @yomi = @tmp[0 .. 2];
    if ( $yomi[2] eq 'ｲｶﾆｹｲｻｲｶﾞﾅｲﾊﾞｱｲ'
         or $yomi[2] =~ / ﾉﾂｷﾞﾆﾊﾞﾝﾁｶﾞｸﾙﾊﾞｱｲ \z/xms
       ) {
        $yomi[2] = q{};
    }
    else {
        $yomi[2] =~ s/ ｲﾁｴﾝ \z//xms;
    }
    my $yomi = join q{}, @yomi;
    $yomi = hw2katakana($yomi);
    $yomi = kata2hira($yomi);

    my @address = @tmp[3 .. 5];
    if ( $address[2] eq '以下に掲載がない場合'
         or $address[2] =~ / の次に番地がくる場合 \z/xms
       ) {
        $address[2] = q{};
    }
    else {
        $address[2] =~ s/ 一円 \z//xms;
    }
    my $address = join q{}, @address;

    my $data = { _key => $zip_code, yomi => $yomi, address => $address };
    if ($i > 0) {
	print ",";
    }
    print "\n";
    print encode_json($data);
    $i++;
}
print "\n]\n"
