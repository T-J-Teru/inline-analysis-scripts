package InlineAnalysis::DwarfTagObject;

use strict;
use warnings;
no indirect;
no autovivification;

use Carp;

=pod

=head1 NAME

DwarfTagObject - Base class for all DW_TAG_ things.

=head1 SYNOPSIS

  Quick code sample should go here...

=head1 METHODS

The methods for this module are listed here:

=over 4

=cut

#============================================================================#

=pod

=item I<Public>: B<depth>

Return the depth of this tag object in the DWARF.

=cut

sub depth {
  my $self = shift;
  return $self->{__depth__};
}

#========================================================================#

=pod

=item I<Public>: B<id>

Return the ID for this tag object, this is the offset into the DWARF with
the '0x' prefix.

=cut

sub id {
  my $self = shift;
  return $self->{__id__};
}

#========================================================================#

=pod

=item I<Private>: B<_get_attribute>

Take a name string, return the DWARF attribute with that name.

=cut

sub _get_attribute {
  my $self = shift;
  my $name = shift;

  return $self->{__attr__}->{$name};
}

#========================================================================#

=pod

=item I<Public>: B<new>

Create a new instance of DwarfTagObject and then call initialise
on it.

=cut

sub new {
  my $class = shift;

  #-----------------------------#
  # Don't change this method    #
  # Change 'initialise' instead #
  #-----------------------------#

  my $self  = bless {}, $class;
  $self->initialise(@_);
  return $self;
}

#============================================================================#

=pod

=item I<Private>: B<initialise>

Initialise this instance of this class.

=cut

sub initialise {
  my $self = shift;
  my %args = @_;

  (exists ($args{-id})) or
    croak ("missing -id parameter");
  $self->{__id__} = $args{-id};

  (exists ($args{-depth})) or
    croak ("missing -depth parameter");
  $self->{__depth__} = $args{-depth};

  (exists ($args{-attributes})) or
    croak ("missing -attributes parameter");
  ref ($args{-attributes}) eq 'HASH' or
    croak ("the -attributes parameter is not a HASH reference");
  $self->{__attr__} = $args{-attributes};
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
