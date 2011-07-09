use strict;
use warnings;
use utf8;
use Lingua::JA::Moji qw/hw2katakana kata2hira/;
use JSON;
use IPC::Cmd qw/run/;

open my $ken_all_csv, '<:encoding(shiftjis)', 'KEN_ALL.CSV'
    or die 'failed to open KEN_ALL.csv';

#my $data;
while ( my $record = <$ken_all_csv> ) {
    my ($zip_code, @tmp) = ( split /,/, $record )[2 .. 8];

    foreach my $value ($zip_code, @tmp) {
        $value =~ s/\A "(.*)" \z/$1/xms;
    }

    # fix yomi
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

    # fix address
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
    my ($ok, $err) = load->($data);
    die $err unless $ok;
#    push @{ $data }, { _key => $zip_code, address => $address };
}

#my ($ok, $err) = load->($data);
#warn $ok ? "complete" : $err;

sub load {
    my $data = shift;

    $data = encode_json($data);

    return run(
        command => [
            'groonga',
            '/home/wata/db/groonga/Groonga-Suggest/groonga_suggest.db',
            'load',
            '--values',
            "\'$data\'",
            '--table',
            'KEN_ALL',
        ],
        buffer  => \my $buf,
    );
}
