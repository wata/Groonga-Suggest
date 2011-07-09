use strict;
use warnings;
use utf8;
use JSON;
use IPC::Cmd qw/run/;

open my $ken_all_csv, '<:encoding(shiftjis)', 'KEN_ALL.CSV'
    or die 'failed to open KEN_ALL.csv';

#my $data;
while ( my $record = <$ken_all_csv> ) {
    my ($zip_code, @address) = ( split /,/, $record )[2, 6, 7, 8];

    foreach my $value ($zip_code, @address) {
        $value =~ s/\A "(.*)" \z/$1/xms;
    }

    if ( $address[2] eq '以下に掲載がない場合'
         or $address[2] =~ / の次に番地がくる場合 \z/xms
       ) {
        $address[2] = q{};
    }
    else {
        $address[2] =~ s/ 一円 \z//xms;
    }
    my $address = join q{}, @address;

    my $data = { _key => $zip_code, address => $address };
    my ($ok, $err) = load->($data);
    unless ($ok) {
        die $err;
    }
#    push @{ $data }, { _key => $zip_code, address => $address };
}

#my ($ok, $err) = load->($data);
#unless ($ok) {
#    die $err;
#}

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
