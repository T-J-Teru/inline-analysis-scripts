package InlineAnalysis;

use strict;
use warnings;
no indirect;
no autovivification;

use InlineAnalysis::DwarfReader;
use InlineAnalysis::InlinedSubroutine;
use InlineAnalysis::Subprogram;
use InlineAnalysis::InlineData;

use Carp;

#========================================================================#

my $DEC = "\\d+";
my $HEX = "[0-9a-f]+";

#========================================================================#

=pod

=head1 NAME

InlineAnalysis - Tools for performing inline analysis on a file.

=head1 SYNOPSIS

  Quick code sample should go here...

=head1 METHODS

The methods for this module are listed here:

=over 4

=cut

#========================================================================#

=pod

=item I<Static> I<Private>: B<_clean_value>

Currently undocumented.

=cut

sub _clean_value {
  my $value = shift;

  $value =~ s/\(indirect string, offset: 0x$HEX\)://;
  $value =~ s/^\s+//;

  if ($value =~ m/^<(0x$HEX)>$/)
  {
    $value = $1;
  }

  return $value;
}

#============================================================================#

=pod

=item I<Static> I<Private>: B<parse_attr>

Currently undocumented.

=cut

sub _parse_attr {
  my $reader = shift;

  my %attr;
  while (my $line = $reader->peek_line ())
  {
    chomp $line;

    if ($line =~ m/^ <$DEC><$HEX>: Abbrev Number:/)
    {
      return %attr;
    }
    elsif ($line =~ m/^\s+<$HEX>\s+(DW_AT_\S+)\s*:\s+(.*)$/)
    {
      my ($type,$value) = ($1,$2);
      $value = _clean_value ($value);
      if (exists ($attr{$type}))
      {
        croak ("attribute '$type' aleady exists");
      }
      $attr{$type} = $value;
      $reader->get_line ();
    }
    else
    {
      croak ("unable to parse attribute line '$line'");
    }
  }

  croak ("unexpected end of attribute list");
}

#========================================================================#

=pod

=item I<Static> I<Public>: B<ParseDwarf>

Take a single parameter I<-filename>, parse the DWARF information in that
file and return an InlineAnalysis::InlineData object.

=cut

sub ParseDwarf {
  my %args = @_;

  (exists $args{-filename}) or
    croak ("Missing -filename parameter");
  my $filename = $args{-filename};

  my $reader = InlineAnalysis::DwarfReader->new (-filename => $filename);

  my @subprograms;
  my @parsing_subprograms;
  while ($_ = $reader->get_line ())
  {
    chomp;

    if (m/^ <($DEC)><($HEX)>: Abbrev Number: 0$/)
    {
      my $depth = $1;
      my $id = $2;

      # Found an end marker.
      if (scalar (@parsing_subprograms))
      {
        if ($depth <= ($parsing_subprograms[0]->{-depth} + 1))
        {
          my $prog = shift @parsing_subprograms;
          $prog = InlineAnalysis::Subprogram->new (%{$prog});
          push @subprograms, $prog;
        }
      }
    }
    elsif (m/^ <($DEC)><($HEX)>: Abbrev Number: $DEC \(([^)]+)\)$/)
    {
      # Found the start of a new DW_TAG_ element.
      my $depth = $1;
      my $id = "0x$2";
      my $type = $3;

      if (@parsing_subprograms)
      {
        if ($parsing_subprograms[0]->{-depth} == $depth)
        {
          my $prog = shift @parsing_subprograms;
          $prog = InlineAnalysis::Subprogram->new (%{$prog});
          push @subprograms, $prog;
        }
      }

      if ($type eq "DW_TAG_subprogram")
      {
        my %attr = _parse_attr ($reader);
        unshift @parsing_subprograms, ({ -attributes => \%attr,
                                         -id => $id,
                                         -depth => $depth,
                                         -inlined => [] });
      }
      elsif ($type eq "DW_TAG_inlined_subroutine")
      {
        if (not (@parsing_subprograms))
        {
          croak ("found a DW_TAG_inlined_subroutine outside of a subprogram");
        }

        my %attr = _parse_attr ($reader);
        if (not (exists ($attr{DW_AT_abstract_origin})))
        {
          croak ("missing DW_AT_abstract_origin for inlined subroutine at $id");
        }

        my $prog = $parsing_subprograms[0];
        my $inlined
          = InlineAnalysis::InlinedSubroutine->new
          (-id => $id, -depth => $depth, -attributes => \%attr);
        push @{$prog->{-inlined}}, $inlined;
      }
    }
  }

  if (scalar (@parsing_subprograms))
  {
    croak ("reached end of DWARF with partially parsed subprogram");
  }

  my $data = InlineAnalysis::InlineData->new (-filename => $filename,
                                              -subprograms => \@subprograms);
  return $data;
}

#============================================================================#

=pod

=back

=head1 AUTHOR

Andrew Burgess, 19 Mar 2019

=cut

#============================================================================#
#Return value of true so that this file can be used as a module.
1;
