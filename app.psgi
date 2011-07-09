use strict;
use warnings;
use Plack::Request;
use URI;
use Furl::HTTP;

my $app = sub {
    my $env = shift;
    my $req = Plack::Request->new($env);

    my $html = do { local $/; <DATA> };

    if ( my $q = $req->param('q') ) {
        my $ua = Furl::HTTP->new;
        my $u  = URI->new('http://localhost:10041/d/select');
        $u->query_form(
            table          => 'KEN_ALL',
#            match_columns  => '_key,address,yomi',
            query          => 'address:@' . $q,
#            output_columns => '_key,address',
            sortby         => '_id',
            limit          => '-1',
        );
        my ( undef, $code, undef, undef, $body ) = $ua->get($u);
        return [ 200, [ 'Content-Type' => 'application/json' ], [ $body ] ] if $code eq 200;
    }
    return [ 200, [ 'Content-Type' => 'text/html' ], [ $html ] ];
};

__DATA__
<!doctype html>
<html lang="ja">
<head>
<meta charset="utf-8">
<title>Groonga Suggest</title>
<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.5.1/jquery.min.js"></script>
<script type="text/javascript">
  $(document).ready(function() {
    $('input#search').keydown(function() {
      $.get('/search', {"q":$(this).val()}, function(json) {
        var data = json.join(',');
        $('div#address').html(data);
      });
    });

    $('input#search').focus();
  });
</script>
</head>
<body>
<form>
  <div><input id="search" type="text" /></div>
  <div id="address"></div>
</form>
</body>
</html>
