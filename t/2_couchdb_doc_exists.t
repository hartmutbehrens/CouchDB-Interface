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

my $content = {'name' => 'lauren','surname' => 'snyman'};
$couch->save_doc({id => 'first_doc', content => $content});	#id specified, will run a PUT request

subtest 'Document EXISTS' => sub {
	is($couch->exists_doc({id => 'does_not_exist'}), 0, 'No document check OK');
	is($couch->exists_doc({id => 'first_doc'}), 1, 'Document check OK');
};

done_testing();