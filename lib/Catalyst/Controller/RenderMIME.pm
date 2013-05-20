package Catalyst::Controller::RenderMIME;
use strict;
use warnings;

our $VERSION = 0.01;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

use Catalyst::Utils;
use HTML::TokeParser::Simple;
use Data::Dumper::Concise 'Dumper';
use RapidApp::Include qw(sugar perlutil);
 

# ---
# Supply code to obtain the MIME object via either coderef attr or
# extending get_mime() method
has 'get_mime_coderef', is => 'ro', isa => 'CodeRef', lazy => 1, default => sub {
  sub { (shift)->get_mime(@_) }
};
sub get_mime { ... }
# ---

has 'expose_methods', is => 'ro', isa => 'Bool', default => 0;

sub content :Local {
  my ($self, $c, $id, @path) = @_;
  my $MIME = $self->_resolve_path($c, $id, @path);
  
  my $cid_path = '/' . $self->action_namespace($c) . "/content/$id/cid";
  return $self->_view_part($c,$MIME,$cid_path);
}


sub method :Local {
  my ($self, $c, $method, $id, @path) = @_;
  
  $c->res->header( 'Content-Type' => 'text/plain' );
  
  unless( $self->expose_methods ) {
    $c->res->body('MIME Object Methods Disabled (see "expose_methods")');
    return $c->detach;
  }
  
  my $MIME = $self->_resolve_path($c, $id, @path);
  
  unless( $MIME->can($method) ) {
    $c->res->body("No such method '$method'");
    return $c->detach;
  }
  
  my @ret = $MIME->$method;
  if(scalar @ret > 1) {
     $c->res->body( Dumper(\@ret) );
  }
  else {
    if(ref $ret[0]) {
      $c->res->body( Dumper($ret[0]) );
    }
    else {
      $c->res->body( $ret[0] );
    }
  }
  
  return $c->detach;
}



sub _resolve_path {
  my ($self, $c, $MIME, $next, @path) = @_;
  
  # $MIME is either a MIME object or the key/id of a MIME object:
  unless (blessed $MIME) {
    $MIME = $self->get_mime_coderef->($self,$c,$MIME)
      # Idealy the derived class will throw its own exception
      or Catalyst::Exception->throw("Content '$MIME' not found");
    
    Catalyst::Exception->throw(
      "get_mime/get_mime_coderef did not return an Email::MIME object"
    ) unless (blessed $MIME && $MIME->isa('Email::MIME'));
  }
  
  return $MIME unless ($next);
  $next = lc($next);
  
  my $SubPart;
  
  # Resolve by part index tree or cid
  if($next eq 'cid' || $next eq 'content-id') {
    my $cid = shift @path;
    $SubPart = $self->_resolve_cid($MIME,$cid);
  }
  else {
    # Assume 'part'
    $next = shift @path if ($next eq 'part');

    my $idx = $next;
    Catalyst::Exception->throw("Bad MIME Part Index '$idx' - must be an integer")
      unless ($idx =~ /^\d+$/);
      
    $SubPart = ($MIME->parts)[$idx]
      or Catalyst::Exception->throw("MIME Part not found at index '$idx'");
  }
  
  # Continue recursively:
  return $self->_resolve_path($c,$SubPart,@path);
}


sub _resolve_cid {
  my ($self, $MIME, $cid) = @_;
  
  my $FoundPart;
	
	$MIME->walk_parts(sub {
		my $Part = shift;
		return if ($FoundPart);
		$FoundPart = $Part if ( $Part->header('Content-ID') and (
			$cid eq $Part->header('Content-ID') or 
			'<' . $cid . '>' eq $Part->header('Content-ID')
		));
	});
  
  Catalyst::Exception->throw('Content-ID ' . $cid . ' not found.')
    unless ($FoundPart);
    
  return $FoundPart;
}

sub _render_part {
  my ($self, $c, $MIME, $cid_path) = @_;
  
  $self->_set_mime_headers($c,$MIME);
  
  my $body = $MIME->body;
  $self->_convert_cids(\$body,$cid_path) 
    if ($MIME->content_type =~ /^text/);
  
  $c->res->body( $body );
  return $c->detach;
}


sub _set_mime_headers {
  my ($self, $c, $MIME) = @_;
  
  # TODO: find all the headers that will cause issues like the date/cookie
  my @exclude_headers = qw(Date); 
  my %excl = map {$_=>1} @exclude_headers;
  my @header_names = grep { !$excl{$_} } $MIME->header_names;
  $c->res->header( $_ => $MIME->header($_) ) for (@header_names);

}

sub _view_part {
  my ($self, $c, $MIME, $cid_path) = @_;
  
  my @parts = $MIME->parts;
  my $Rich = try{($parts[0]->parts)[1]};
  
  return $self->_render_part($c, $MIME, $cid_path) unless (
    defined $Rich
    and $Rich->content_type =~ /^text/
  );

  $self->_set_mime_headers($c,$Rich);
	
	my $p = '<p style="margin-top:3px;margin-bottom:3px;">';
	
	my $html = '';
	
	$html .= '<div style="font-size:90%;">';
	#$html .= $p . '<b>' . $_ . ':&nbsp;</b>' . join(',',$Rich->header($_)) . '</p>' for ($Rich->header_names);
	$html .= $p . '<b>' . $_ . ':&nbsp;</b>' . join(',',$MIME->header($_)) . '</p>' for (qw(From Date To Subject));
	$html .= '</div>';
	
	$html .= '<hr><div style="padding-top:15px;"></div>';
	
	$html .= $Rich->body_str;
	
	$self->_convert_cids(\$html,$cid_path);
	
	$c->res->body( $html );
  return $c->detach;
}




sub _convert_cids {
  my ($self, $htmlref, $cid_path) = @_;

	my $parser = HTML::TokeParser::Simple->new($htmlref);
	
	my $substitutions = {};
	
  # currently only doing img and a tags:
  
	while (my $tag = $parser->get_tag) {
	
		my $attr;
		if($tag->is_tag('img')) {
			$attr = 'src';
		}
		elsif($tag->is_tag('a')) {
			$attr = 'href';
		}
		else {
			next;
		}
		
		my $url = $tag->get_attr($attr) or next;
    my ($prefix,$cid) = split(/\:/,$url,2);
		next unless (lc($prefix) eq 'cid' && $cid);
		
    # Replace the CID URL with a url back to this controller:
		my $find = $tag->as_is;
		$tag->set_attr($attr,"$cid_path/$cid");
		$substitutions->{$find} = $tag->as_is;
	}
	
	foreach my $find (keys %$substitutions) {
		my $replace = $substitutions->{$find};
		$$htmlref =~ s/\Q$find\E/$replace/gm;
	}
}


1;