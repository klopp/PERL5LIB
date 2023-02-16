package Atomic::Task::Thread;

# ------------------------------------------------------------------------------
use threads;
use threads::shared;
use Modern::Perl;
#use Thread::Shared;

use lib q{..};
use Atomic::Task::Pool;
use base qw/Atomic::Task::Pool/;

our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
sub new
{
    my ( $class, $tasks, $params ) = @_;
    return $class->SUPER::new( $tasks, $params );
}

# ------------------------------------------------------------------------------
sub run
{
    my ( $self, $children ) = @_;

    use DDP;

    #    say np $self;

    my @tasks;
    while ( my ( undef, $task ) = each %{ $self->{tasks} } ) {
        push @tasks, $task;
        for ( 0 .. @{ $task->{resources} } - 1 ) {

            #share( $task->{resources}->[$_] );
            #$task->{resources}->[$_] = shared_clone( $task->{resources}->[$_] );
            #share( $task->{resources}->[$_] );
            #bless( $task->{resources}->[$_], ( ref $task->{resources}->[$_] ) . '::Shared' );
#            $task->{resources}->[$_] = Thread::Shared::convert( $task->{resources}->[$_] );
#            say np $task->{resources}->[$_];
        }
    }

    #    share @{$_} for @{ $self->{resources} };
    #    bless( $_, (ref $_) . '::Shared' ) for @{ $self->{resources} };
    #    my @tasks = values %{ $self->{tasks} };

    my $idx : shared;
    threads->create(
        sub {
            $idx //= 0;
            my @pieces = splice @tasks, $idx, $self->{params}->{pieces};
            $idx += $self->{params}->{pieces};
            ( $_ and $_->run ) for @pieces;
#            ( $_ and $_ = Thread::Shared::unwrap($_) ) for @pieces;
        }
    ) for 1 .. $self->{params}->{children};
    $_->join for threads->list;
}

=for comment
    
#!/usr/bin/env perl

use strict;
use warnings;

package MyObject;

sub new {
   my ( $class, %args ) = @_;
   my $self = \%args;
   bless $self, $class;
   return $self;
}

sub get_value {
   my ( $self, $key ) = @_;
   return $self->{$key} // 0;
}

sub set_value {
   my ( $self, $key, $value ) = @_;
   $self->{$key} = $value;
}

package main;

use threads;
use Storable qw ( freeze thaw );
use Thread::Queue;

my $work_q   = Thread::Queue->new;
my $result_q = Thread::Queue->new;

sub worker {
   while ( my $serialised = $work_q->dequeue ) {
      my $local_obj = thaw $serialised;
      print threads->self->tid, " is processing object with id ",
        $local_obj->get_value('id'), "\n";
      $local_obj->set_value( 'processed_by', threads->self->tid );
      $result_q->enqueue( freeze $local_obj );
   }
}

threads->create( \&worker ) for 1 .. 10;

for ( 1 .. 100 ) {
   my $obj = MyObject->new( id => $_ );
   $work_q->enqueue( freeze $obj );
}
$work_q->end;
$_->join for threads->list;

while ( my $ser_obj = $result_q->dequeue_nb ) {
   my $result_obj = thaw $ser_obj;
   print "Object with ID of :", $result_obj->get_value('id'),
     " was processed by thread ", $result_obj->get_value('processed_by'),
     "\n";
}
    
=cut

# ------------------------------------------------------------------------------
1;
__END__
