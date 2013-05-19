package MimeCas::Schema::ResultSet::MimeObject;
require base; base->import('DBIx::Class::ResultSet');

use strict;
use warnings;

use RapidApp::Include qw(sugar perlutil);

use Email::MIME;
use Digest::SHA1;
use Try::Tiny;

sub schema { (shift)->result_source->schema };


sub sha1s_only {
  my $self = shift;
  return $self->search_rs(undef,{ colummns => 'sha1' });
}

sub store_mime {
  my $self = shift;
  my $data = shift;
  
  # TMP FOR MYSQL - set max packet to 500MB
  $self->schema->storage->dbh->do('SET GLOBAL max_allowed_packet=' . 500 * 1024 * 1024);
  
  my ($MIME, $parse_error, $died);
  if(ref $data) {
    $MIME = $data;
  }
  else {
    try {
      local $SIG{__WARN__} = sub { 
        $parse_error ||= ''; 
        $parse_error .= "$_\n";
      };
      $MIME = Email::MIME->new($data); 
    }
    catch { 
      $died = 1; 
      $parse_error ||= ''; 
      $parse_error .= "$_\n"; 
    };
  }
  
  # If we couldn't parse the MIME object we save the raw
  # content with the error
  if($died) {
    my $sha1 = $self->calculate_checksum($data);
    return $self->_find_or_create_mime_row({
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
    return $self->_find_or_create_mime_row({
      content => $content,
      direct_children => $direct_children,
      all_children => $all_children,
      child_objects => [
        # TODO: sometimes this rel/sub insert encounters duplicates... how/why?
        map {{ child_sha1 => $_, order => $order++ }} @children
      ],
      parse_error => $parse_error
    },$MIME);
  }
  else {
    return $self->_find_or_create_mime_row({ parse_error => $parse_error },$MIME);
  }
}



# This function is general purpose and supposed multiple modes of use.
# see where it is called for details (since it is still *private*, it
# does assume it is being called with correct data)
sub _find_or_create_mime_row {
  my $self = (shift)->sha1s_only;
  my $create = shift || {};
  my $MIME = shift;
  
  $create->{sha1} ||= do {
    $create->{content} //= $MIME->as_string;
    $self->calculate_checksum($create->{content});
  };
  
  return $self->find($create->{sha1}) || do {

    $create->{direct_children} //= 0;
    $create->{all_children} //= 0;
    
    if($MIME) {
      $create->{mime_headers} //= $self->get_headers_packet($create->{sha1},$MIME);
      $create->{parsed} //= 1;
    };
    
    ## Call in void context to prevent trying to select the row back in:
    $self->populate([$create]);
    #$self->populate(\@cols,[ map { $create->{$_} } @cols ]);
    
    $self->find($create->{sha1});
  };
}




sub get_headers_packet {
  my $self = shift;
  my $sha1 = shift;
  my $MIME = shift;
  
  my $mime_headers = [];
  my $header_ord = 0;
  my @headers = ($MIME->header_pairs);
  while(scalar @headers > 0) {
    my $name = shift @headers;
    my $value = shift @headers;
    push @$mime_headers, {
      sha1 => $sha1,
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
