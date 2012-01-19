package CouchDB::Interface::Connector;
# ABSTRACT: CouchDB::Interface::Connector - internal package that makes sure you have a connection to the CouchDB

#pragmas
use feature qw(say);
use strict;
use warnings;

#modules
use Carp qw(confess);
use CouchDB::Interface::Request;
use Moo;

has uri => ( is => 'ro', isa => \&_connected, required => 1 );

before 'uri' => sub { $_[0]->{uri} .= '/' unless $_[0]->{uri} =~ m{/$}; };

sub _connected {
	my $request = CouchDB::Interface::Request->new(uri => $_[0], method => 'get');
	my $response = $request->execute;
	return 1 if (defined $response->code) && ($response->code == 200);
	
	my $code_txt = defined $response->code ? ' Response code: '.$response->code : ''; 
	my $err_txt = defined $response->error ? ' Error: '.$response->error : '';
	confess 'Could not connect to ', $_[0], join('.',$code_txt,$err_txt),"\n";
}

1;

=pod
=attr uri
The CouchDB server URI
=cut
__END__