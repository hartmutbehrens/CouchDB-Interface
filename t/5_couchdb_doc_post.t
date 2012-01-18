#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(say);

use Data::Dumper;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../lib";
use CouchDB::Interface;

my $uri = 'http://hartmut:vodacom@hartmut.iriscouch.com/';
my $couch = new_ok('CouchDB::Interface' => [uri => $uri, name => 'docs_testing', debug => 1]);

subtest 'Document POST' => sub {
	my $content = {'name' => 'laurenhartmut','surname' => 'snymanbehrens'};
	
	my $data = $couch->save_doc({content => $content});		#no id specified generates a POST request
	is(defined $data->{ok} && $data->{ok} == 1, 1, 'Document POST OK');
	is(defined $data->{id}, 1, 'Document POST assigned id OK');
};

done_testing();