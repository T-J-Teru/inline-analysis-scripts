#!/usr/bin/perl

use warnings;
use strict;
no indirect;
no autovivification;

#========================================================================#

=pod

=head1 NAME

compare-symbols-sizes - a quick summary of what compare-symbols-sizes does.

=head1 OPTIONS

B<compare-symbols-sizes> [-h|--help]

=head1 SYNOPSIS

A full description for compare-symbols-sizes has not yet been written.

=cut

#========================================================================#

use lib "$ENV{HOME}/lib";
use GiveHelp qw/usage/;         # Allow -h or --help command line options.
use Carp::Assert;

#========================================================================#

exit (main (@ARGV));

#========================================================================#

=pod

=head1 METHODS

The following methods are defined in this script.

=over 4

=cut

#========================================================================#

=pod

=item B<all_syms_of_type>

First parameter is a string, all the other parameters are sets of symbol
size data as returned from I<read_symbol_sizes>.

=cut

sub all_syms_of_type {
  my $type = shift;
  my @sizes = @_;

  my %syms;
  foreach my $set (@sizes)
  {
    foreach my $name (keys %{$set})
    {
      if ($set->{$name}->{-type} eq $type)
      {
        $syms{$name} = 1;
      }
    }
  }

  return sort (keys %syms);
}

#========================================================================#

=pod

=item B<main>

Main program, takes @ARGV as parameter list.

=cut

sub main {
  my $file1 = shift;
  my $file2 = shift;

  (defined $file1) and (defined $file2) or
    die "Missing two files on the command line";

  my $sizes1 = read_symbol_sizes ($file1);
  my $sizes2 = read_symbol_sizes ($file2);

  printf "%40s %10s %10s %10s\n", "Symbol", "Before", "After", "Diff";
  print "-"x73 . "\n";

  my @local_syms = all_syms_of_type ('LOCAL', $sizes1, $sizes2);
  my @global_syms = all_syms_of_type ('GLOBAL', $sizes1, $sizes2);

  my %ignore = (before => 0, after => 0);
  my %total = (before => 0, after => 0);
  foreach my $type (qw/LOCAL GLOBAL/)
  {
    print "$type:\n";

    my @sym_names = ($type eq 'LOCAL') ? @local_syms : @global_syms;
    foreach my $sym (@sym_names)
    {
      my $before_val = undef;
      if (exists ($sizes1->{$sym}))
      {
        assert (ref ($sizes1->{$sym}) eq 'HASH');
        $before_val = $sizes1->{$sym}->{-size};
      }
      my $after_val = undef;
      if (exists ($sizes2->{$sym}))
      {
        assert (ref ($sizes2->{$sym}) eq 'HASH');
        $after_val = $sizes2->{$sym}->{-size};
      }

      (defined ($before_val)) or $before_val = 0;
      (defined ($after_val)) or $after_val = 0;

      my $ignore = ignore_symbol ($sym);

      if ($ignore)
      {
        $ignore{before} += $before_val;
        $ignore{after} += $after_val;
      }

      $total{before} += $before_val;
      $total{after} += $after_val;

      my $diff = $after_val - $before_val;
      my $prefix = "";

      if ($before_val > 200 && $diff > 100)
      {
        if ($ignore)
        {
          $prefix = "I*>";
        }
        else
        {
          $prefix = "**>";
        }
      }
      elsif ($ignore)
      {
        $prefix = "I";
      }

      printf "%-3s%37s %10s %10s %10s\n",
        $prefix, $sym, $before_val, $after_val, $diff;
    }
  }

  print "-"x73 . "\n";
  printf "%40s %10s %10s %10s\n", "Ignored Symbols",
    $ignore{before}, $ignore{after}, ($ignore{after} - $ignore{before});
  printf "%40s %10s %10s %10s\n", "Total Symbols",
    $total{before}, $total{after}, ($total{after} - $total{before});

  return 0;
}

#========================================================================#

=pod

=item B<ignore_symbol>

Takes the name of a symbol, return true if the symbol should be ignored
from the results display.

=cut

sub ignore_symbol {
  my $symbol = shift;

  return ($symbol =~ m/^_/);
}

#========================================================================#

=pod

=item B<read_symbol_sizes>

Take a I<filename>, return a hash-reference.  In the hash the keys are the
names of the symbols in I<filename> and the values are the sizes of the
symbols.

Only global function symbols are returned in the hash.

=cut

sub read_symbol_sizes {
  my $filename = shift;

  my %syms;

  open my $in, "readelf -s $filename |"
    or die "Failed to open pipe from readelf on '$filename': $!";

  while (<$in>)
  {
    chomp;

    next unless m/^\s+\d+:\s+[0-9a-f]+\s+(\d+)\s+FUNC\s+(\S+)\s+\S+\s+\S+\s+(\S+)/;
    my ($name, $type, $size) = ($3, $2, $1);

    assert (($type eq 'LOCAL') or ($type eq 'GLOBAL'));

    $syms{$name} = { -name => $name,
                     -type => $type,
                     -size => $size };
  }

  close $in
    or die "Failed to close pipe from readelf on '$filename': $!";

  return \%syms;
}

#========================================================================#

=pod

=back

=head1 AUTHOR

Andrew Burgess, 04 Feb 2019

=cut
