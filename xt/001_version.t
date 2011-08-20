use strict;
use warnings;
use utf8;
use Test::More;

my $got = `$^X bin/watcher --version`;
like $got, qr{^watcher: [0-9._]+$};

done_testing;

