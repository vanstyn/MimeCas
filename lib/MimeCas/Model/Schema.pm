package MimeCas::Model::Schema;
use Moose;
extends 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
    schema_class => 'MimeCas::Schema',
    
    connect_info => {
        dsn => 'dbi:SQLite:dbname=mime_cas.db',
        on_connect_call => 'use_foreign_keys',
        quote_names => 1,
    }
);

# Auto-deploy:
before 'setup' => sub {
  my $self = shift;
  return if (-f 'mime_cas.db');
  $self->schema_class->connect($self->connect_info->{dsn})->deploy;
};

1;
