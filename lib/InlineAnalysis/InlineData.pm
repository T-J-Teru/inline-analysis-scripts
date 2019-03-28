package InlineAnalysis::InlineData;

use strict;
use warnings;
no indirect;
no autovivification;

use Carp;

=pod

=head1 NAME

InlineAnalysis::InlineData - All inlining data.

=head1 SYNOPSIS

  Quick code sample should go here...

=head1 METHODS

The methods for this module are listed here:

=over 4

=cut

#============================================================================#

=pod

=item I<Private>: B<_find_subprogram_by_name>

Take a name as a string, find the matching subprogram, or return undef if
non is found.

=cut

sub _find_subprogram_by_name {
  my $self = shift;
  my $name = shift;

  my @p;
  foreach my $p (@{$self->{__subprograms__}})
  {
    if ($p->name ($self) eq $name)
    {
      push @p, $p;
    }
  }

  my $found = undef;
  foreach my $p (@p)
  {
    my $s = $p->size ();
    if (defined ($s) and ($s > 0))
    {
      $found = $p;
    }
  }

  return $found;
}

#========================================================================#

=pod

=item I<Private>: B<_find_subprogram_by_id>

Take a single InlineAnalysis::DwarfTagObject id and find the corresponding
subprogram, or return undef if non is found.

=cut

sub _find_subprogram_by_id {
  my $self = shift;
  my $id = shift;

  if (exists ($self->{__subprograms_hash__}->{$id}))
  {
    return $self->{__subprograms_hash__}->{$id};
  }

  foreach my $p (@{$self->{__subprograms__}})
  {
    my $i = $p->id ();
    if (not (exists ($self->{__subprograms_hash__}->{$i})))
    {
      $self->{__subprograms_hash__}->{$i} = $p;
      return $p if ($i eq $id);
    }
  }

  return undef; # Not found.

}

#========================================================================#

=pod

=item I<Public>: B<find_subprogram>

Take either a I<-id> or I<-name> parameter, and find the matching
subprogram.

=cut

sub find_subprogram {
  my $self = shift;
  my %args = @_;

  (exists $args{-id}) and (exists $args{-name}) and
    croak ("can't pass -id and -name to find_subprogram");

  if (exists $args{-id})
  {
    return $self->_find_subprogram_by_id ($args{-id});
  }
  elsif (exists $args{-name})
  {
    return $self->_find_subprogram_by_name ($args{-name});
  }
  else
  {
    croak ("missing either -id or -name for find_subprogram");
  }
}

#========================================================================#

=pod

=item I<Public>: B<subprograms>

Return a list of all InlineAnalysis::Subprogram objects.

=cut

sub subprograms {
  my $self = shift;
  return @{$self->{__subprograms__}};
}

#========================================================================#

=pod

=item I<Public>: B<new>

Create a new instance of InlineAnalysis::InlineData and then call
initialise on it.

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
    croak ("missing -filename parameter");
  $self->{__filename__} = $args{-filename};

  (exists $args{-subprograms}) or
    croak ("missing -subprograms parameter");
  (ref ($args{-subprograms}) eq 'ARRAY')
    or croak ("the -subprograms parameter is not a list");
  $self->{__subprograms__} = $args{-subprograms};
  $self->{__subprograms_hash__} = {};
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
