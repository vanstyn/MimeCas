package MimeCas::Model::Schema;
use Moose;
extends 'Catalyst::Model::DBIC::Schema';

use Path::Class qw(file);
use Catalyst::Utils;

my $db = file(Catalyst::Utils::home('MimeCas'),'mime_cas.db');

__PACKAGE__->config(
    schema_class => 'MimeCas::Schema',
    
    connect_info => {
        dsn => 'dbi:SQLite:dbname=' . $db,
        #on_connect_call => 'use_foreign_keys',
        quote_names => 1,
    }
);

# Auto-deploy:
before 'setup' => sub {
  my $self = shift;
  return if (-f $db);
  $self->schema_class->connect($self->connect_info->{dsn})->deploy;
};

1;
