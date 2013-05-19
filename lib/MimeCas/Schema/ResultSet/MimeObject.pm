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
  
  my @subparts = $MIME->subparts;
  if(@subparts > 0) {
    my $content = '';
    my @children = ();
    foreach my $Part (@subparts) {
      my $ChildRow = $self->store_mime($Part);
      my $child_sha1 = $ChildRow->get_column('sha1');
      $content .= $child_sha1 . ' ' . $Part->content_type . "\n";
      push @children, $child_sha1;
    }
    my $order = 0;
    return $self->_find_or_create_mime_row($MIME,{
      content => $content,
      children => scalar(@children),
      mime_graph_parent_sha1s => [
        map {{ child_sha1 => $_, order => $order++ }} @children
      ]
    });
  }
  else {
    return $self->_find_or_create_mime_row($MIME);
  }
}


sub _find_or_create_mime_row {
  my $self = shift;
  my $MIME = shift;
  my $create = shift || {};
  
  $create->{content} ||= $MIME->as_string;

  my $sha1 = $self->calculate_checksum($create->{content});
  return $self->find($sha1) || $self->create({
    sha1 => $sha1,
    children => 0,
    mime_headers => $self->get_headers_packet($MIME),
    %$create
  });
}


sub get_headers_packet {
  my $self = shift;
  my $MIME = shift;
  
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

  return $mime_headers;
}


sub calculate_checksum {
	my $self = shift;
	my $data = shift;
	
	my $sha1 = Digest::SHA1->new->add($data)->hexdigest;
	return $sha1;
}


1;
