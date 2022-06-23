use v6;
#use Test;

#use YAMLish;
#use Gnome::Gtk3::Window;
#use Gnome::Gdk3::Window;
use Gnome::T::Run;

#-------------------------------------------------------------------------------
=begin pod

=head1 Gnome::T

Main entry of test framework

=head1 Description

B<Gnome::T> class is the top level of the user interface test framework. To use tne class run your program like so;

  raku -MGnome::T my-gui-program.raku --Ttest-protocol.yaml

=head2 Options

=item C<-MGnome::T>; loads the module where this class resides. C<-M> is a Raku option.
=item C<my-gui-program.raku>; is the gui program to test
=item C<--Ttest-protocol.yaml>; test the gui using this test protocol. C<--T> is the modules option.

=head2 Test protocol


=end pod

#-------------------------------------------------------------------------------
# This class inherits from TopLevelClassSupport not for the storage of a native
# object but for the use of its routines and triggering of the test mode.
class Gnome::T:auth<github:MARTIMM> {

  #-----------------------------------------------------------------------------
  has Gnome::T::Run $!run;


  #-----------------------------------------------------------------------------
  =begin pod

  =end pod
  #-----------------------------------------------------------------------------
  submethod BUILD ( ) {

#note "Args: $*PROGRAM-NAME, @*ARGS.raku()";

    (my $protocol-file = @*ARGS.grep(/^'--' T '='?/)) ~~ s/^'--' T '='?//;
    unless ?$protocol-file {
      $protocol-file = $*PROGRAM-NAME;
      $protocol-file ~~ s/\. \w* $/.yaml/;
    }

    $!run .= new(:$protocol-file);
  }


  #-----------------------------------------------------------------------------
  =begin pod

  =end pod
  #-----------------------------------------------------------------------------
  method run-test-protocol ( ) {
#    $*log-file-handle.print("Run tests ...\n");
#    diag "Run tests ...";
    $!run.run-tests;
#    $*log-file-handle.print("Done testing ...\n");
#    diag "Done testing ...";
  }
}


#-------------------------------------------------------------------------------
# create as soon as possible to prevent start of event loop
#diag "prepare tests";
my Gnome::T $*T;

#-------------------------------------------------------------------------------
# only after the users gui is created and displayed we can start the tests
END {

  $*T .= new;

  #-----------------------------------------------------------------------------
  # variables set in Gnome::T
  my IO::Handle $*log-file-handle;
  my DateTime $*log-time;

  #-----------------------------------------------------------------------------
  $*T.run-test-protocol;
}
