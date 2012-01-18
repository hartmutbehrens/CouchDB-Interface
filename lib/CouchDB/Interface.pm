package CouchDB::Interface;

=head1 NAME
CouchDB::Interface;
=cut

#pragmas
use strict;
use warnings;
use feature qw(say);

#modules
use Carp qw(confess);
use CouchDB::Interface::Request;
use Moo;
use Try::Tiny;

extends 'CouchDB::Interface::Connector';

has name => (is => 'rw', required => 1);
has debug => (is => 'rw', default => sub { return 0} );

sub all_dbs {
	my $self = shift;
	my $request = CouchDB::Interface::Request->new(uri => $self->uri.'_all_dbs', debug => $self->debug, method => 'get');
	my $response = $request->execute;
	my $rv = $self->is_response($response,200);
	return defined $rv ? $rv->json : undef; 
}

sub has_db {
	my $self = shift;
	my $name = shift // $self->name;
	return (grep { $_ eq $name } @{$self->all_dbs()}) ? 1 : 0;
}

sub create_db {
	my $self = shift;
	my $name = shift // $self->name;
	my $uri = $self->uri.$name.'/';
	my $request = CouchDB::Interface::Request->new(uri => $uri, debug => $self->debug, method => 'put');
	my $response = $request->execute;
	my $rv = $self->is_response($response,201);
	return defined $rv ? $rv->json : undef; 
}

sub del_db {
	my $self = shift;
	my $name = shift // $self->name;
	my $uri = $self->uri.$name.'/';
	my $request = CouchDB::Interface::Request->new(uri => $uri, debug => $self->debug, method => 'delete');
	my $response = $request->execute;
	my $rv = $self->is_response($response,200);
	return defined $rv ? $rv->json : undef; 
}

sub db_uri {
	my $self = shift;
	return $self->uri.$self->name.'/'; 
}

sub doc_uri {
	my ($self,$par) = @_;
	my $uri = $self->db_uri.$par->{id};
	$uri .= '?rev='.$par->{rev} if defined $par->{rev};
	return $uri; 
}

sub _fetch {
	my ($self,$ids,$path) = @_; 
	confess "An arrray reference is expected" unless ref $ids eq 'ARRAY';
	
	my $request = CouchDB::Interface::Request->new(uri => $self->db_uri.$path, content => {'keys' => $ids}, debug => $self->debug, method => 'post');
	my $response = $request->execute;
	return $response->json if $response->code == 200;
	$request->complain($response);
}

sub get_multiple {
	my ($self,$ids,$params) = @_;
	return $self->_fetch($ids,'_all_docs'.$self->par_to_string($params));
}

sub get_multiple_with_doc {
	my ($self,$ids,$params) = @_;
	return $self->_fetch($ids,'_all_docs?include_docs=true'.$self->par_to_string($params));
}

sub update {
	my ($self,$docs) = @_;
	$self->insert($docs);
}

sub insert {
	my ($self,$docs) = @_;
	confess "An arrray reference is expected" unless ref $docs eq 'ARRAY';
	$self->_get_rev($docs);
	my $request = CouchDB::Interface::Request->new(uri => $self->db_uri.'_bulk_docs', content => {'docs' => $docs}, debug => $self->debug, method => 'post');
	my $response = $request->execute;
	return $response->json if $response->code == 201;
	$request->complain($response);
}

sub par_to_string {
	my ($self,$params) = @_;
	my $string = defined $params ? '&'.join( '&' ,map($_.'="'.$params->{$_}."'" ,keys %$params)) : '';
	return $string;
}

#get revision, if one is available
sub _get_rev {
	my ($self,$docs) = @_;
	my %index;
	for my $i (0..$#$docs) {
		$index{$docs->[$i]->{_id}} = $i if defined $docs->[$i]->{_id};	#some docs may not have _id defined (POST request to Couch will assign _id)
	}
	my $ids = $self->get_multiple( [keys %index] );
	for my $id (@{$ids->{rows}}) {
		next unless defined $id->{value};
		$docs->[$index{$id->{id}}]->{_rev} = $id->{value}->{rev};	
	}
}

sub exists_doc {
	my ($self,$params) = @_;
	return 1 if $self->get_doc($params);
	return 0;
}

sub get_doc {
	my ($self,$params) = @_;
	my $request = CouchDB::Interface::Request->new(uri => $self->doc_uri($params), debug => $self->debug, method => 'get');
	my $response = $request->execute;
	my $rv = $self->is_response($response,200);
	return defined $rv ? $rv->json : undef; 
}

sub is_response {
	my ($self,$response,$expected) = @_;
	if ($response) {
		return $response if defined $response->code && $response->code == $expected;
	}
	return undef;
}

sub save_doc {
	my ($self,$params) = @_;
	if ($params->{id}) {
		return $self->_put_doc($params);
	}
	else {
		return $self->_post_doc($params);
	}
}

sub _put_doc {
	my ($self,$params) = @_;
	
	my $doc = $self->get_doc($params);
	$params->{content}->{_rev} = $doc->{_rev} if $doc;	#if doc already exists, then fill in revision number unless it was provided
	
	my $request = CouchDB::Interface::Request->new(uri => $self->doc_uri($params), debug => $self->debug, method => 'put', content => $params->{content});
	my $response = $request->execute;
	my $rv = $self->is_response($response,201);
	return defined $rv ? $rv->json : undef; 
}

sub _post_doc {
	my ($self,$params) = @_;
	my $request = CouchDB::Interface::Request->new(uri => $self->db_uri, debug => $self->debug, method => 'post', content => $params->{content});
	my $response = $request->execute;
	my $rv = $self->is_response($response,201);
	return defined $rv ? $rv->json : undef; 
}

sub delete_doc {
	my ($self,$params) = @_;
	my $doc = $self->get_doc($params);
	if ($doc) {
		$params->{rev} = $doc->{_rev};
		my $request = CouchDB::Interface::Request->new(uri => $self->doc_uri($params), debug => $self->debug, method => 'delete');
		my $response = $request->execute;
		my $rv = $self->is_response($response,200);
		return defined $rv ? $rv->json : undef;
	}
	return undef;
}

1;
