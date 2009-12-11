# -*- perl -*-
# If a script is already exiting non-zero (and non-1),
# make sure File::Coda doesn't clobber it.

(my $ME = $0) =~ s|.*/||;

use Test::More;
use File::Temp 'tmpnam';
use Errno;
use POSIX qw(strerror);

umask 077;

my ($script_fh, $script_name) = tmpnam;
my $err_output = tmpnam;

printf $script_fh <<'-', $^X;
#!%s -Tw -Iblib/lib
use File::Coda;
$ENV{LC_ALL} = 'C'; # Ensure that diagnostics are in English.
print 'anything';
exit 2;
-
close $script_fh
  or die "$ME: $script_name: write failed: $!\n";
chmod 500 => $script_name;

my @expect = ('ME: closing standard output: ' . strerror(&Errno::EBADF) ."\n");

plan tests => 1 + @expect;

{
    local %ENV =
      (
       (map { $_ => $ENV{$_} || 'undef' } qw(HOME PATH LOGNAME USER SHELL)),
      );

    system "$script_name >&- 2> $err_output";
}

my $exit_status = $? >> 8;
is $exit_status, 2, 'exit code of sample script';

my $i = 0;
open ERROR, '<', $err_output;
while (@expect && defined (my $line = <ERROR>)) {
    chomp $line;

    # What we expect to see, (from below).
    my $expect = shift @expect;
    chomp $expect;
    $line =~ s!^.*?:!ME:!;

    # Generate a description of this test
    my $desc = "stderr line " . ++$i;

    like $line, qr/^$expect$/, $desc;
}
close ERROR;

unlink $script_name, $err_output;
