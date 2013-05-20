package MimeCas::Controller::Mime;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller::RenderMIME'; }

has '+expose_methods', default => 1;

sub get_mime {
  my ($self, $c, $id) = @_;
  
  my $MimeObj = $c->model('Schema::MimeObject')->find($id)
    or return undef;
    
  return $MimeObj->Mime;


}


__PACKAGE__->meta->make_immutable;

1;
