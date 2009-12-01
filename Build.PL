#!/usr/bin/perl

use strict;
use warnings;
use Module::Build;

my $b = new Module::Build
  (
   module_name => 'File::Coda',
   license => 'gpl',
   dist_author => 'Jim Meyering <jim@meyering.net>',
   dist_abstract => 'a global destructor to close stdout carefully',
   dist_version_from => 'Coda.pm',
   pm_files => { 'Coda.pm' => 'lib/File/Coda.pm' },
   build_requires => {
      'Test::Pod' => '0',
      'Test::Pod::Coverage' => '0',
   },
  );
$b->create_build_script;
