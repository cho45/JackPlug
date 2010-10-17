#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
sub p ($) { warn Dumper shift }

use Perl6::Say;

use lib glob 'modules/*/lib';
use lib 'lib';

use URI::Escape;
use LWP::Simple qw($ua);
use Term::ReadLine;
use JSON::XS;

sub short_ua ($) {
	my $ua = shift;
	local $_ = $ua;
	/Chrome/ and return 'Chrome';
	/Safari/ and return 'Safari';
	/Opera/  and return 'Opera';
	return $ua;
}

my $term = Term::ReadLine->new('Simple Perl calc');
my $prompt = "> ";
my $OUT = $term->OUT || \*STDOUT;
while (defined ($_ = $term->readline($prompt))) {
	warn $@ if $@;
	my $res = $ua->get('http://localhost:5000/api/run?m=' . uri_escape($_));
	my $data = decode_json $res->content;
	# say $res->content;
	my $results = $data->{results};
	for my $key (keys %$results) {
		say short_ua $key;
		say "\t" . $results->{$key}->{body};
	}
	$term->addhistory($_) if /\S/;
}

