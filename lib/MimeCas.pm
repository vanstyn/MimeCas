package MimeCas;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

use FindBin;
use lib "$FindBin::Bin/../rapidapp/lib";
use RapidApp::Include qw(sugar perlutil);

my @plugins = qw(
    -Debug
    Static::Simple
    RapidApp::RapidDbic
);

use Catalyst;

our $VERSION = '0.01';
our $TITLE = "MimeCas v" . $VERSION;

__PACKAGE__->config(
  name => 'MimeCas',
  # Disable deprecated behavior needed by old applications
  disable_component_resolution_regex_fallback => 1,

  'Plugin::RapidApp::RapidDbic' => {
    title => $TITLE,
    nav_title => 'MIME Cas Store',
    #dashboard_template => 'templates/dashboard.tt',
    banner_template => 'templates/rapidapp/simple_auth_banner.tt',
    dbic_models => ['Schema'],
    hide_fk_columns => 1,
    configs => {
      Schema => {
        TableSpecs => {
          MimeObject => {
            columns => {
              sha1 => { width => 250 },
              content => { hidden => \1, renderer => jsfunc 'function(v){ return "<pre>" + v + "</pre>"; }' },
              original =>  { no_column => \1, no_quick_search => \1, no_multifilter => \1 },
              mime_graph_child_sha1s =>  { no_column => \1, no_quick_search => \1, no_multifilter => \1 },
              mime_graph_parent_sha1s =>  { no_column => \1, no_quick_search => \1, no_multifilter => \1 },
            }
          },
          MimeGraph => {
            columns => {
              child_object => { width => 250 },
              parent_object => { width => 250 },
            }
          }
          
        }
      
      }
    }
  },
);

# Start the application
__PACKAGE__->setup(@plugins);

1;
