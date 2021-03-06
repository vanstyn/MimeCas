package MimeCas;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;
use RapidApp 0.99024;
use Catalyst::Controller::MIME 0.02;
use Email::Date 1.103;

use RapidApp::Include qw(sugar perlutil);

#use Carp::Always;

my @plugins = qw(
    -Debug
    Static::Simple
    RapidApp::RapidDbic
);

push @plugins, qw(RapidApp::AuthCore);
push @plugins, qw(RapidApp::NavCore);
#push @plugins, qw(RapidApp::RequestLogger);
push @plugins, qw(RapidApp::CoreSchemaAdmin);

use Catalyst;

our $VERSION = '0.12';
our $TITLE = "MimeCas v" . $VERSION;

__PACKAGE__->config(
  name => 'MimeCas',
  # Disable deprecated behavior needed by old applications
  disable_component_resolution_regex_fallback => 1,
  
  'Plugin::RapidApp::TabGui' => {
    title => $TITLE,
    nav_title => 'MIME Cas Store',
    dashboard_url => '/tple/dashboard.tt',
    banner_template => 'banner.html',
    template_navtree_regex => '.', #<-- ALL templates, including rapidapp built-ins
  },
  
  'Controller::RapidApp::Template' => {
    #auto_editable => 1,
    access_params => {
      writable => 1,
      creatable => 1,
      deletable => 1,
      #writable_regex => '^wiki',
      #creatable_regex => '^wiki',
      ##admin_tpl_regex => '^wiki_admin',
      #non_admin_tpl_regex => '^wiki',
    }
  },
  
  'Plugin::AutoAssets' => { assets => [
    # Example manual asset controller
    {
      controller => 'A::Img',
      type => 'IconSet',
      include => 'root/static/images',
      allow_static_requests => 1
    
    },
    #{
    #  controller => 'A::CSS::Scoped',
    #  type => 'CSS',
    #  include => 'root/static/reset.css',
    #  allow_static_requests => 1,
    #  scopify => ['div.scoped-reset', merge => ['html','body']]
    #
    #}
  ]},
  

  'Plugin::RapidApp::RapidDbic' => {
    
    # TODO: 'page_view_dir' is no longer a thing, but I'm leaving
    # this comment as a reminder to come back for the content
    # that was hosted here for demos...
    #page_view_dir => 'root/pages',

    dbic_models => [
      'Schema',
      #'RapidApp::CoreSchema'
    ],
    hide_fk_columns => 1,
    configs => {
      Schema => {
        grid_params => {
          '*defaults' => {
            include_colspec => ['*', '*.*'],
            destroyable_relspec => ['*'], #<-- allow delete
            #cache_total_count => 0 #<-- turn this off while lots of data is changing
            
          },
          MailMessage => {
            include_colspec => ['*', '*.*', 'sha1.mime_attribute.*'],
          
          }
        },
        virtual_columns => {
          MimeObject => {
            view_link => {
              data_type => "varchar",
              is_nullable => 0,
              size => 255,
              
              # MySQL syntax:
              #sql => 'SELECT CONCAT("<a target=\"_blank\" href=\"/mime/view/",CONCAT(self.sha1,"\">Open</a>"))'
              
              #SQLite syntax:
              #sql => q~SELECT '<a target="_blank" href="/mime/view/' || self.sha1 || '">Open</a>'~
              sql => q~SELECT '<a href="#!/mime/view/' || self.sha1 || '">Open</a>'~
            },
          }
        },
        TableSpecs => {
          MailFolder => {
            title => 'Folder',
            title_multi => 'Folders',
            iconCls => 'icon-folder',
            multiIconCls => 'icon-folders',
            display_column => 'name'
          },
          MailMessage => {
            title => 'Message',
            title_multi => 'Messages',
            iconCls => 'icon-mail-earth',
            multiIconCls => 'icon-mail-earths',
          },
          Mailbox => {
            title => 'Mailbox',
            title_multi => 'Mailboxes',
            iconCls => 'ra-icon-database',
            multiIconCls => 'ra-icon-database-table',
            display_column => 'name'
          },
          MimeAttribute => {
            title => 'Mime Attribute',
            title_multi => 'Mime Attributes',
            columns => {
              debug_structure => { 
                 renderer => jsfunc 'function(v){ return "<pre>" + v + "</pre>"; }' 
               },
            }
          },
          MimeGraph => {
            title => 'Mime Graph',
            title_multi => 'Mime Graphs',
            iconCls => 'icon-node',
            multiIconCls => 'icon-nodes',
            columns => {
              child_object => { width => 250 },
              parent_object => { width => 250 },
            }
          },
          MimeHeader => {
            title => 'Mime Header',
             title_multi => 'Mime Headers',
            iconCls => 'icon-news',
            multiIconCls => 'icon-newspapers',
          },
          MimeObject => {
            title => 'Mime Part',
            title_multi => 'Mime Parts',
            iconCls => 'icon-email',
            multiIconCls => 'icon-emails',
            columns => {
              sha1 => { width => 250 },
              content => { 
                hidden => \1,
                #no_quick_search => \1,
                renderer => jsfunc 'function(v){ return "<pre>" + v + "</pre>"; }' 
              },
              original =>  { no_column => \1, no_quick_search => \1, no_multifilter => \1 },
              mime_graph_child_sha1s =>  { no_column => \1, no_quick_search => \1, no_multifilter => \1 },
              mime_graph_parent_sha1s =>  { no_column => \1, no_quick_search => \1, no_multifilter => \1 },
              virtual_size => { profiles => ['filesize'] },
              actual_size => { profiles => ['filesize']  },
              view_link =>  { no_quick_search => \1, no_multifilter => \1, sortable => \0 },
            }
          },
          MimeRecipient => {
            title => 'Mime Recipient',
            title_multi => 'Mime Recipients',
            iconCls => 'ra-icon-user',
            multiIconCls => 'ra-icon-group',
          
          }

          
        }
      
      }
    }
  },
);

# Start the application
__PACKAGE__->setup(@plugins);

1;
