use strict;
use warnings;
use Test::More;


use Catalyst::Test 'MimeCas';
use MimeCas::Controller::Bs;

ok( request('/bs')->is_success, 'Request should succeed' );
done_testing();
