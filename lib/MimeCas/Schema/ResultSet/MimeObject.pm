package MimeCas::Schema::ResultSet::MimeObject;
require base; base->import('DBIx::Class::ResultSet');

use strict;
use warnings;

use RapidApp::Include qw(sugar perlutil);

use Email::MIME;
use Digest::SHA1;
use Try::Tiny;

sub schema { (shift)->result_source->schema };


sub store_mime {
  my $self = shift;
  my $data = shift;
  
  my ($MIME, $parse_error);
  if(ref $data) {
    $MIME = $data;
  }
  else {
    try { $MIME = Email::MIME->new($data); }
    catch { $parse_error = $_ };
  }
  
  # If we couldn't parse the MIME object we save the raw
  # content with the error
  if($parse_error) {
    my $sha1 = $self->calculate_checksum($data);
    return $self->find($sha1) || $self->create({
      sha1 => $sha1,
      content => $data,
      parsed => 0,
      parse_error => $parse_error
    });
  }
  
  # temp for debug
  #local $_ = $data;

  my @subparts = $MIME->subparts;
  if(@subparts > 0) {
    # Save a "fake" version of the MIME object. Same headers, but instead of
    # the actual body we store a list of child checksums. This ensures that
    # our checksum will consider the entire nested content without all the
    # duplicate storage. This works exactly the same as Git
  
    my $content = $MIME->header_obj->as_string . "\n---MimeCas Child Parts SHA1 Checksums---\n";
    my @children = ();
    my $grand_children = 0;
    foreach my $Part (@subparts) {
      my $content_type = $Part->content_type;
      my $ChildRow = $self->store_mime($Part);
      $grand_children += $ChildRow->get_column('all_children');
      my $child_sha1 = $ChildRow->get_column('sha1');
      $content .= "$child_sha1\n";
      push @children, $child_sha1;
    }
    my $order = 0;
    my $direct_children = scalar(@children);
    my $all_children = $direct_children + $grand_children;
    return $self->_find_or_create_mime_row($MIME,{
      content => $content,
      direct_children => $direct_children,
      all_children => $all_children,
      child_objects => [
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
  
  # temp for debug:
  #$create->{original} = $_;

  my $sha1 = $self->calculate_checksum($create->{content});
  return $self->find($sha1) || $self->create({
    sha1 => $sha1,
    parsed => 1,
    direct_children => 0,
    all_children => 0,
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
