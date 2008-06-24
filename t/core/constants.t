#============================================================= -*-perl-*-
#
# t/constants.t
#
# Test the Badger::Constants.pm module.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use strict;
use warnings;

use lib qw( ./lib ../lib ../../lib );
use Badger::Constants ':types';
use Test::More tests => 2;

ok(1, 'loaded Badger::Constants' );
is( HASH, Badger::Constants::HASH, 'HASH is ' . HASH );



__END__

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
