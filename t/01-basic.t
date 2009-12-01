# -*- perl -*-
# Ensure that the write error is reported.
(my $ME = $0) =~ s|.*/||;

use Test::More;
use File::Temp 'tmpnam';

umask 077;

my ($script_fh, $script_name) = tmpnam;
my $err_output = tmpnam;

printf $script_fh <<'-', $^X;
#!%s -Tw -Iblib/lib
use File::Coda;
$ENV{LC_ALL} = 'C'; # Ensure that diagnostics are in English.
print 'anything';
-
close $script_fh
  or die "$ME: $script_name: write failed: $!\n";
chmod 500 => $script_name;

my @expect = <DATA>;
my $have_dev_full = -e '/dev/full';
$have_dev_full
  or @expect = grep { !/No space/ } @expect;

plan tests => 1 + @expect;

{
    local %ENV =
      (
       (map { $_ => $ENV{$_} || 'undef' } qw(HOME PATH LOGNAME USER SHELL)),
      );

    system "$script_name >&-               2> $err_output";
    $have_dev_full
      and system "$script_name > /dev/full 2>> $err_output";
}

my $exit_status = $? >> 8;
is $exit_status, 1, 'exit code of sample script';

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

__END__
ME: closing standard output: Bad file descriptor
ME: closing standard output: No space left on device
