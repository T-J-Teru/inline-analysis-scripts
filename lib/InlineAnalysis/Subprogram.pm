package InlineAnalysis::Subprogram;

use strict;
use warnings;
no indirect;
no autovivification;

use base qw/InlineAnalysis::DwarfTagObject/;

use Carp;
use Carp::Assert;

=pod

=head1 NAME

InlineAnalysis::Subprogram - Hold information about a single subprogram
tag.

=head1 SYNOPSIS

  Quick code sample should go here...

=head1 METHODS

The methods for this module are listed here:

=over 4

=cut

#============================================================================#

=pod

=item I<Public>: B<size>

Return the size of this sub-program in bytes, or undef if the size is not
known.

=cut

sub size {
  my $self = shift;
  my $high_pc =  $self->_get_attribute ("DW_AT_high_pc");
  if (defined ($high_pc))
  {
    return hex ($high_pc);
  }
  return undef;
}

#========================================================================#

=pod

=item I<Public>: B<inlined>

Return a list of all inlined subroutines.

=cut

sub inlined {
  my $self = shift;
  return @{$self->{__inlined__}};
}

#========================================================================#

=pod

=item I<Public>: B<name>

Return the name of this sub-program.

=cut

sub name {
  my $self = shift;
  my $data = shift;

  (defined ($data) and ($data->isa ("InlineAnalysis::InlineData"))) or
    croak ("missing InlineAnalysis::InlineData required for name lookup");

  my $name =  $self->_get_attribute ("DW_AT_name");
  if (not (defined ($name)))
  {
    my $ao = $self->_get_attribute ("DW_AT_abstract_origin");
    (defined ($ao)) or
      croak ("missing name and abstract origin");

    my $parent = $data->find_subprogram (-id => $ao);
    (defined ($parent)) or
      croak ("failed to find parent subprogram with id $ao");

    $name = $parent->name ($data);
    # my $id = $self->id ();
    # $name = $name." [out-of-line instance] ";
  }

  assert (defined ($name));
  return $name;
}

#========================================================================#

=pod

=item I<Public>: B<has_inlining>

Return true if this subprogram has anything inlined within it.

=cut

sub has_inlining {
  my $self = shift;
  return (scalar (@{$self->{__inlined__}}) > 0);
}

#========================================================================#

=pod

=item I<Private>: B<initialise>

Initialise this instance of this class.

=cut

sub initialise {
  my $self = shift;
  my %args = @_;

  $self->SUPER::initialise (%args);

  (exists ($args{-inlined})) or
    croak ("missing -inlined parameter");
  (ref ($args{-inlined}) eq 'ARRAY') or
    croak ("the -inlined parameter is not a list");
  $self->{__inlined__} = $args{-inlined};
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
