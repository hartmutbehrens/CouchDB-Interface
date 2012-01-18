#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(say);

use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../lib";
use CouchDB::Interface;

my $uri = 'http://hartmut:vodacom@hartmut.iriscouch.com/';
my $couch = new_ok('CouchDB::Interface' => [uri => $uri, name => 'docs_testing', debug => 1]);

subtest 'Document GET' => sub {
	SKIP: {
		skip 'first_doc not available for testing', 1 unless $couch->exists_doc({id => 'first_doc'});
		my $data = $couch->get_doc({id => 'first_doc'});
		is(defined $data->{_rev}, 1, 'Document retrieval OK');
	}
	
	my $data = $couch->get_doc({id => 'bogus'});
	is($data, undef, 'Non-existent document retrieval handled OK');
};

done_testing();