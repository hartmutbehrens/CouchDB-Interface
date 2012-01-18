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

subtest 'Document PUT' => sub {
	my $content = {'name' => 'lauren','surname' => 'snyman'};
	
	$couch->delete_doc({id => 'first_doc'});	#delete doc, if it exists
	
	my $data = $couch->save_doc({id => 'first_doc', content => $content});	#id specified, will run a PUT request
	is(defined $data->{ok} && $data->{ok} == 1, 1, 'Document PUT OK');
	my $fetched = $couch->get_doc({id => 'first_doc'});
	is($fetched->{name},$content->{name}, 'Document content OK');
	
	$content->{name} = 'hartmut';
	$data = $couch->save_doc({id => 'first_doc', content => $content});
	is(defined $data->{ok} && $data->{ok} == 1, 1, 'Document PUT with updated content OK');
	$fetched = $couch->get_doc({id => 'first_doc'});
	is($fetched->{name},$content->{name}, 'Document content update OK');
	
	$content->{address} = 'sunningdale';
	$data = $couch->save_doc({id => 'first_doc', content => $content});
	is(defined $data->{ok} && $data->{ok} == 1, 1, 'Document PUT with new content OK');
	$fetched = $couch->get_doc({id => 'first_doc'});
	is($fetched->{address},$content->{address}, 'Document new content update OK');
	
};

done_testing();