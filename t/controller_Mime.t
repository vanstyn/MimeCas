use strict;
use warnings;
use Test::More;


use Catalyst::Test 'MimeCas';
use MimeCas::Controller::Mime;

ok( request('/mime')->is_success, 'Request should succeed' );
done_testing();
