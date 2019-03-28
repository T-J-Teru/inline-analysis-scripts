package InlineAnalysis::InlinedSubroutine;

use strict;
use warnings;
no indirect;
no autovivification;

use base qw/InlineAnalysis::DwarfTagObject/;

=pod

=head1 NAME

InlineAnalysis::InlinedSubroutine - Information for one inilned subroutine.

=head1 SYNOPSIS

  Quick code sample should go here...

=head1 METHODS

The methods for this module are listed here:

=over 4

=cut

#============================================================================#

=pod

=item I<Public>: B<abstract_origin>

Return the abstract_origin ID, a hex string with '0x' prefix.

=cut

sub abstract_origin {
  my $self = shift;
  return $self->{__abstract_origin__};
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

  my $ao = $self->_get_attribute ("DW_AT_abstract_origin");
  (defined ($ao)) or
    croak ("missing DW_AT_abstract_origin attribute");
  $self->{__abstract_origin__} = $ao;
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
