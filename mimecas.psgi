use strict;
use warnings;

use MimeCas;

my $app = MimeCas->apply_default_middlewares(MimeCas->psgi_app);
$app;

