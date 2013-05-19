package MimeCas::Schema::ResultSet::MimeObject;
require base; base->import('DBIx::Class::ResultSet');

use strict;
use warnings;

use RapidApp::Include qw(sugar perlutil);

use Email::MIME;
use Digest::SHA1;

sub schema { (shift)->result_source->schema };


sub store_mime {
  my $self = shift;
  my $data = shift;
  
  my $MIME = ref $data ? $data : Email::MIME->new($data);
  
  scream($MIME->debug_structure);
  
  my @subparts = $MIME->subparts;
  if(@subparts > 0) {
    foreach my $Part (@subparts) {
      $self->store_mime($Part);
    
    }
  
  }
  else {
    return $self->_find_or_create_mime_leaf($MIME);
  }
}


sub _find_or_create_mime_leaf {
  my $self = shift;
  my $MIME = shift;
  
  my $as_string = $MIME->as_string;
  my $sha1 = $self->calculate_checksum($as_string);
  
  my $Row = $self->find($sha1);
  unless($Row) {
  
    my $mime_headers = [];
    my $header_ord = 0;
    my @headers = ($MIME->header_pairs);
    while(scalar @headers > 0) {
      my $name = shift @headers;
      my $value = shift @headers;
      push @$mime_headers, {
        name => lc($name),
        value => $value,
        order => $header_ord++
      };
    }
    
    $Row = $self->create({
      sha1 => $sha1,
      content => $MIME->as_string,
      children => 0,
      mime_headers => $mime_headers,
      
    });
  
  }
  
  return $Row;
  
  
}



sub calculate_checksum {
	my $self = shift;
	my $data = shift;
	
	my $sha1 = Digest::SHA1->new->add($data)->hexdigest;
	return $sha1;
}


1;
