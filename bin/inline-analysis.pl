#!/usr/bin/perl

use warnings;
use strict;
no indirect;
no autovivification;

#========================================================================#

=pod

=head1 NAME

inline-analysis - a quick summary of what inline-analysis does.

=head1 OPTIONS

B<inline-analysis> [-h|--help] FILE1 [FILE2]

=head1 SYNOPSIS

Where I<FILE1> is the compiled binary with inlinging turned on, and
I<FILE2> is an optional version of the same file compiled with inlining
turned off.

=cut

#========================================================================#

use FindBin;
use lib "$ENV{HOME}/lib";
use lib "$FindBin::Bin/../lib/";
use GiveHelp qw/usage/;         # Allow -h or --help command line options.
use InlineAnalysis;
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

=item B<find_inlined_subprogram>

Currently undocumented.

=cut

sub find_inlined_subprogram {
  my $data = shift;
  my $inlined_subroutine = shift;

  my $ao = $inlined_subroutine->abstract_origin ();
  my $subprogram = $data->find_subprogram (-id => $ao);
  assert (defined ($subprogram));
  return $subprogram;
}

#========================================================================#

=pod

=item B<main>

Currently undocumented.

=cut

sub main {
  my $filename = shift;
  (defined $filename) or usage ();

  my $filename2 = shift;

  print "Analysing: $filename\n";

  my $data = InlineAnalysis::ParseDwarf (-filename => $filename);
  my $data2 = undef;
  if (defined $filename2)
  {
    $data2 = InlineAnalysis::ParseDwarf (-filename => $filename2);
  }

  my %was_inline;
  foreach my $subprogram ($data->subprograms ())
  {
    next if (not ($subprogram->has_inlining ()));

    my $top_level_name = $subprogram->name ($data);
    print_inline_tree ($data, $data2, $subprogram);

    foreach my $i ($subprogram->inlined ())
    {
      my $inlined_subprogram = find_inlined_subprogram ($data, $i);
      my $name = $inlined_subprogram->name ($data);

      # Build up data about what is inlined into what.
      if (not (exists $was_inline{$name}))
      {
        $was_inline{$name} = { count => 0,
                               name => $name,
                               inlined_in => {} };
      }
      $was_inline{$name}->{count}++;
      $was_inline{$name}->{inlined_in}->{$top_level_name} = $subprogram;
    }
  }

  my @problem_inlines;
  foreach my $name (keys (%was_inline))
  {
    if ($was_inline{$name}->{count} > 1)
    {
      print "WARNING: Function `$name` was inlined ".
        $was_inline{$name}->{count}." times\n";
      push @problem_inlines, $was_inline{$name};
    }
  }

  print "\n";

  foreach my $entry (@problem_inlines)
  {
    my $name = $entry->{name};
    my $str = "Function '$name':";

    my $totals = { with_inline => {},
                   no_inline => {} };

    print "$str\n";
    print "="x(length($str))."\n";
    print "\n";

    foreach my $tln (keys %{$entry->{inlined_in}})
    {
      my $subprogram = $entry->{inlined_in}->{$tln};
      print_inline_tree ($data, $data2, $subprogram, $totals);
    }

    my ($total1, $total2) = (0, 0);
    foreach my $v (values %{$totals->{with_inline}})
    {
      $total1 += $v;
    }
    foreach my $v (values %{$totals->{no_inline}})
    {
      $total2 += $v;
    }

    printf "%-50s\t\t%d\t\t%d","TOTAL:", $total1, $total2;

    if ($total1 > $total2)
    {
      print "\t[BAD - Could save ".($total1 - $total2)."]";
    }
    print "\n\n";
  }

  print "\n\n";
}

#========================================================================#

=pod

=item B<print_inline_tree>

Currently undocumented.

=cut

sub print_inline_tree {
  my $data = shift;
  my $data2 = shift;
  my $subprogram = shift;
  my $totals = shift;

  my $width = 50;

  my $top_level_name = $subprogram->name ($data);
  printf "%-${width}s",$top_level_name;
  print "\t\t";
  print $subprogram->size ();
  $totals->{with_inline}->{$top_level_name} = $subprogram->size ();

  if (defined $data2)
  {
    my $other = $data2->find_subprogram (-name => $top_level_name);
    print "\t\t";
    if (defined $other)
    {
      print $other->size ();
      $totals->{no_inline}->{$top_level_name} = $other->size ();
    }
    else
    {
      print "N/A";
    }
  }

  print "\n";
  my @depth = ($subprogram->depth ());
  my $sdepth = 0;

  foreach my $i ($subprogram->inlined ())
  {
    my $nsp = find_inlined_subprogram ($data, $i);
    my $nsp_name = $nsp->name ($data);

    while ($i->depth () <= $depth[0])
    {
      $sdepth -= 2;
      shift @depth; # Discard.
    }

    $sdepth += 2;
    unshift @depth, $i->depth ();

    assert ($sdepth > 0);
    {
      my $str = (" "x$sdepth).$nsp_name;
      printf "%-${width}s", $str;
    }
    if (defined $data2)
    {
      my $other = $data2->find_subprogram (-name => $nsp_name);
      print "\t\t\t\t";
      if (defined $other)
      {
        print $other->size ();
        $totals->{no_inline}->{$nsp_name} = $other->size ();
      }
      else
      {
        print "N/A";
      }
    }
    print "\n";
  }

  print "\n";
}

#========================================================================#

=pod

=back

=head1 AUTHOR

Andrew Burgess, 18 Mar 2019

=cut
