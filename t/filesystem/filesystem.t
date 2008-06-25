#============================================================= -*-perl-*-
#
# t/filesystem/filesystem.t
#
# Test the Badger::Filesystem module.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use lib qw( ./lib ../lib ../../lib );
use strict;
use warnings;
use Badger::Filesystem qw( :types :dirs );
use Test::More tests => 11;

our $DEBUG = $Badger::Filesystem::DEBUG = grep(/^-d/, @ARGV);
our $FS    = 'Badger::Filesystem';

my $fs = $FS->new;
ok( $fs, 'created a new filesystem' );

is( $fs->root, ROOTDIR, 'root is ' . ROOTDIR );
is( $fs->updir, UPDIR, 'updir is ' . UPDIR );
is( $fs->curdir, CURDIR, 'curdir is ' . CURDIR );

# alternate names
is( $fs->slash, SLASH, "slash is " . SLASH . " (and also a guitarist in Guns'N'Roses)");
is( $fs->dotdot, DOTDOT, 'dotdot is ' . DOTDOT );
is( $fs->dot, DOT, 'dot is ' . DOT );


#-----------------------------------------------------------------------
# get some files
#-----------------------------------------------------------------------

my $file1 = $fs->file('file.t');
ok( $file1, 'fetched first file' );

my $file2 = $fs->file('filesystem.t');
ok( $file2, 'fetched second file' );

# both should have references to the same $fs filesystem
is( $file1->filesystem, $file2->filesystem, 
    'filesystems are both ' . $file1->filesystem );

is( $file1->filesystem, $fs, 
    'matches our filesystem: ' . $fs );

