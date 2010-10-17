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
my $term = Term::ReadLine->new('Simple Perl calc');
my $prompt = "> ";
my $OUT = $term->OUT || \*STDOUT;
while (defined ($_ = $term->readline($prompt))) {
	warn $@ if $@;
	$ua->get('http://localhost:5000/p?m=' . uri_escape($_));
	$term->addhistory($_) if /\S/;
}
