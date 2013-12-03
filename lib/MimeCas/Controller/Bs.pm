package MimeCas::Controller::Bs;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    
    my $url = '/tple/bs/section/Home.html';
    
    return $c->response->redirect($url)
      unless $c->req->header('X-RapidApp-RequestContentType');
    
    # Show the redirect target as a link in the ExtJS client:
    # need to do this because the Ajax request will act on the redirect!
    $c->response->content_type('text/html; charset=utf8');
    $c->response->body(join('',
      '<b>','302 Redirect: ',
      '<a href="',$url,'">',$url,'</a></b>'
    ));
    return $c->detach;
}

__PACKAGE__->meta->make_immutable;

1;
