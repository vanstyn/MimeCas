package MimeCas::Controller::Bs;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    return $c->response->redirect('/tple/bs/section/Home.html');
}

__PACKAGE__->meta->make_immutable;

1;
