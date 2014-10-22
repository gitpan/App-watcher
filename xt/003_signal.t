use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw(tempdir);
use Time::HiRes qw(time);

my $tmpdir = tempdir(CLEANUP => 0);
my $tmpdir2 = tempdir(CLEANUP => 0);

$ENV{TMPDIR2} = $tmpdir2;

my @cmd = ($^X, 'bin/watcher', "--dir=$tmpdir", '--send_only', '--signal=HUP', '--', $^X, '-e', q[
	warn "GO";
	open my $fh, '>>', "$ENV{TMPDIR2}/x.txt" or die $!;
	select $fh; $|++; select STDOUT;
	print {$fh} "XXX $$\n";
	$SIG{HUP} = sub { print {$fh} "HUP $$\n" };
	$SIG{TERM} = sub { die "TERM" };
	warn "Going to sleep $$";
	for (1..100) {
		sleep(100);
		warn "hmm.. $$";
	}
	sleep(100);
	warn "WROTE $$";
	]);
note "@cmd";

my $pid = fork();
die "Cannot fork: $!" unless defined $pid;
if ($pid==0) { # child
	exec @cmd;
	die "Cannot exec: $!";
} else { # parent
	sleep 1;

	like(read_file(), qr{^XXX \d+\n$});
	update();
	sleep 2;

	like(read_file(), qr{^XXX \d+\nHUP \d+\n$});
	update();
	sleep 2;

	like(read_file(), qr{^XXX \d+\nHUP \d+\nHUP \d+\n$});

	kill 'TERM' => $pid;
	waitpid($pid, 0);
}

done_testing;

sub read_file {
	my $fname = "$tmpdir2/x.txt";
	open my $fh, '<', "$tmpdir2/x.txt" or die "$fname: $!";
	my $src = do { local $/; <$fh> };
	return $src;
}

sub update {
	my $fname = "$tmpdir/@{[ rand ]}.txt";
	diag "updating $fname";

	open my $ofh, '>', $fname or die "$fname: $!";
	print $ofh "YAY " . rand();
	close $ofh;
}
