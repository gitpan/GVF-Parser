#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'GVF::Parser' ) || print "Bail out!\n";
}

diag( "Testing GVF::Parser $GVF::Parser::VERSION, Perl $], $^X" );
