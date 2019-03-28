package InlineAnalysis::DwarfReader;

use strict;
use warnings;
no indirect;
no autovivification;

use Carp;

=pod

=head1 NAME

InlineAnalysis::DwarfReader - Wrapper around reading DWARF.

=head1 SYNOPSIS

  Quick code sample should go here...

=head1 METHODS

The methods for this module are listed here:

=over 4

=cut

#============================================================================#

=pod

=item I<Public>: B<peek_line>

Read and return the next line, but don't discard the line.  Future calls to
I<peek_line> or I<read_line> will return the same line.

=cut

sub peek_line {
  my $self = shift;

  if (not (defined ($self->{__line__})))
  {
    my $fh = $self->{__fh__};
    $self->{__line__} = <$fh>;
  }

  return $self->{__line__};
}

#========================================================================#

=pod

=item I<Public>: B<get_line>

Read and return the next line.  This is destructive, there's currently no
way to unread a line.

=cut

sub get_line {
  my $self = shift;
  if (defined ($self->{__line__}))
  {
    my $line = $self->{__line__};
    $self->{__line__} = undef;
    return $line;
  }

  my $fh = $self->{__fh__};
  my $line = <$fh>;
  return $line;
}

#========================================================================#

=pod

=item I<Private>: B<DESTROY>

Currently undocumented.

=cut

sub DESTROY {
  my $self = shift;
  close ($self->{__fh__}) or
    croak ("failed to close readelf command pipe: $!");
}

#========================================================================#

=pod

=item I<Public>: B<new>

Create a new instance of InlineAnalysis::DwarfReader and then call initialise
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

  (exists $args{-filename}) or
    croak ("Missing -filename parameter");
  my $filename = $args{-filename};

  open my $fh, "-|", "readelf --debug-dump=info $filename" or
    croak ("failed to read DWARF info from '$filename': $!");

  $self->{__filename__} = $filename;
  $self->{__fh__} = $fh;
  $self->{__line__} = undef;
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
