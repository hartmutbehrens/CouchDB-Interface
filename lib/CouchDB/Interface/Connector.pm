package CouchDB::Interface::Connector;

=head1 NAME
CouchDB::Connector;
=cut

#pragmas
use feature qw(say);
use strict;
use warnings;

#modules
#modules
use Carp qw(confess);
use CouchDB::Interface::Request;
use Moo;

has uri => ( is => 'rw', isa => \&connected, required => 1 );

before 'uri' => sub { $_[0]->{uri} .= '/' unless $_[0]->{uri} =~ m{/$}; };

sub connected {
	my $request = CouchDB::Interface::Request->new(uri => $_[0], method => 'get');
	my $response = $request->execute;
	return 1 if (defined $response->code) && ($response->code == 200);
	
	my $code_txt = defined $response->code ? " Response code: ".$response->code : ''; 
	my $err_txt = defined $response->error ? " Error: ".$response->error : '';
	confess "Could not connect to ", $_[0], join('.',$code_txt,$err_txt),"\n";
}

1;