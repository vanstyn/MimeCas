package MimeCas::Schema::ResultSet::MimeObject;
require base; base->import('DBIx::Class::ResultSet');

use strict;
use warnings;

use RapidApp::Include qw(sugar perlutil);

use Email::MIME;
use Email::Address;
use Email::Date;

use Digest::SHA1;
use Try::Tiny;
use DateTime;
use DateTime::Format::Flexible;

sub schema { (shift)->result_source->schema };


sub sha1s_only {
  my $self = shift;
  return $self->search_rs(undef,{ colummns => 'sha1' });
}

sub store_mime {
  my $self = shift;
  my $data = shift;
  
  my %create = ();
  
  # TMP FOR MYSQL - set max packet to 500MB
  $self->schema->storage->dbh->do('SET GLOBAL max_allowed_packet=' . 500 * 1024 * 1024);
  
  my ($MIME, $parse_error, $died);
  if(ref $data) {
    $MIME = $data;
  }
  else {
  
    $create{virtual_size} = length($data);
  
    try {
      local $SIG{__WARN__} = sub { 
        my $msg = shift or return;
        $create{parse_error} ||= ''; 
        $create{parse_error} .= "$msg\n";
      };
      $MIME = Email::MIME->new($data); 
    }
    catch { 
      my $msg = shift or return;
      $died = 1; 
      $create{parse_error} ||= ''; 
      $create{parse_error} .= "$msg\n";
    };
  }
  
  # If we couldn't parse the MIME object we save the raw
  # content with the error
  if($died) {
    my $sha1 = $self->calculate_checksum($data);
    return $self->_find_or_create_mime_row({
      content => $data,
      parsed => 0,
      %create
    });
  }
  
  my @subparts = $MIME->subparts;
  if(@subparts > 0) {
    # Save a "fake" version of the MIME object. Same headers, but instead of
    # the actual body we store a list of child checksums. This ensures that
    # our checksum will consider the entire nested content without all the
    # duplicate storage. This works exactly the same as Git
    
    $create{virtual_size} ||= length($MIME->as_string);
  
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
    my $ordering = 0;
    my $direct_children = scalar(@children);
    my $all_children = $direct_children + $grand_children;
    return $self->_find_or_create_mime_row({
      content => $content,
      direct_children => $direct_children,
      all_children => $all_children,
      child_objects => [
        # TODO: sometimes this rel/sub insert encounters duplicates... how/why?
        map {{ child_sha1 => $_, ordering => $ordering++ }} @children
      ],
      %create
    },$MIME);
  }
  else {
    return $self->_find_or_create_mime_row(\%create,$MIME);
  }
}



# This function is general purpose and supports multiple modes of use.
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
    $create->{virtual_size} //= length($create->{content});
    $create->{actual_size} //= length($create->{content});
    
    if($MIME) {
      $create->{mime_attribute} = $self->get_mime_attribute_packet($create->{sha1},$MIME);
      $create->{mime_headers} //= $self->get_headers_packet($create->{sha1},$MIME);
      $create->{mime_recipients} //= $self->get_mime_recipients_packet($create->{sha1},$MIME);
      $create->{parsed} //= 1;
    };
    
    # Why????
    $self->schema->storage->dbh->do('SET FOREIGN_KEY_CHECKS=0;');
    
    ## Call in void context to prevent trying to select the row back in:
    $self->populate([$create]);
    #$self->populate(\@cols,[ map { $create->{$_} } @cols ]);
    
    $self->find($create->{sha1});
  };
}


sub get_headers_packet {
  my ($self, $sha1, $MIME) = @_;
  
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
      ordering => $header_ord++
    };
  }

  return $mime_headers;
}


sub get_mime_attribute_packet {
  my ($self, $sha1, $MIME) = @_;
  
  my %row = ( sha1 => $sha1 );
  $row{subject} = $MIME->header('Subject');
  $row{message_id} = $MIME->header('Message-ID');
  $row{date} = $self->_time_piece_to_dt(find_date $MIME);
  
  $row{from_addr} = $self->_get_normalized_from($MIME);
  
  ($row{type},$row{subtype}) = $self->_parse_mime_type_subtype($MIME);
  $row{debug_structure} = $MIME->debug_structure if ($MIME->content_type);
  
  return \%row;
}


sub get_mime_recipients_packet {
  my ($self, $sha1, $MIME) = @_;
  
  my $mime_recipients = [];
  my $recipient_ord = 0;
  
  my $To = $MIME->header('To');
  my $CC = $MIME->header('CC');
  
  my @to = $To ? Email::Address->parse($To) : ();
  my @cc = $To ? Email::Address->parse($CC) : ();
  
  push @$mime_recipients, {
    sha1 => $sha1,
    addr => lc($_->address),
    ordering => $recipient_ord++
  } for (@to);
  
  push @$mime_recipients, {
    sha1 => $sha1,
    addr => lc($_->address),
    cc => 1,
    ordering => $recipient_ord++
  } for (@cc);
  
  return $mime_recipients;
}

sub calculate_checksum {
	my $self = shift;
	my $data = shift;
	
	my $sha1 = Digest::SHA1->new->add($data)->hexdigest;
	return $sha1;
}

# lame:
sub _time_piece_to_dt {
  my $self = shift;
  my $t = shift or return undef;
  return DateTime::Format::Flexible->parse_datetime("$t");
}

sub _parse_first_email_address {
  my $self = shift;
  my $addr = shift or return undef;
  my @addresses = Email::Address->parse($addr) or return undef;
  my $Address = shift @addresses or return undef;
  return lc($Address->address);
}

sub _parse_mime_type_subtype {
  my $self = shift;
  my $MIME = shift or return ();
  my $ct = $MIME->content_type or return ();
  ($ct) = split(/\s*\;\s*/,$ct);
  my ($type,$subtype) = split(/\//,$ct,2);
  return (lc($type),lc($subtype));
}


sub _get_normalized_from {
  my $self = shift;
  my $MIME = shift;
  
  my $from = $self->_parse_first_email_address($MIME->header('From'));
  unless($from) {
    $from = $MIME->header('From');
    if($from) {
      # See if this is a obfuscated from (joe at domain.com):
      my ($user,$domain) = split(/\s+at\s+/i,$from,2);
      if($domain) {
        # OK! it is! but we probably need to strip all but the first word:
        ($domain) = split(/\s+/,$domain);
        $from = $user . '@' . $domain;
      }
    }  
  }
  
  return $from;
}


1;
