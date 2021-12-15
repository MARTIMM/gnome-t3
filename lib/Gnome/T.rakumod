use v6;
use Test;

use YAMLish;
#use Gnome::Gtk3::Window;
#use Gnome::Gdk3::Window;
use Gnome::T::Run;

#-------------------------------------------------------------------------------
=begin pod

=end pod

#-------------------------------------------------------------------------------
# This class inherits from TopLevelClassSupport not for the storage of a native
# object but for the use of its routines and triggering of the test mode.
class Gnome::T:auth<github:MARTIMM>:ver<0.6.0> {
#  also is Gnome::Gtk3::Window;

  #`{{
  my Gnome::T $T .= new;

  END {
    my Gnome::GObject::Type $type .= new;

  note "Args: $*PROGRAM-NAME, @*ARGS.raku(), $T._get-builders()";
    (my $protocol-file = @*ARGS.grep(/^'--' T '='?/)) ~~ s/^'--' T '='?//;
    unless ?$protocol-file {
      $protocol-file = $*PROGRAM-NAME;
      $protocol-file ~~ s/\. \w* $/.yaml/;
    }

  #  $builder = $T._get-builders[0];

  #  for @($T._get-builders) -> $b {
  #    my Gnome::Glib::SList $list = $b.get-objects;
  #note "nbr objs; $list.length()";
  #`{{
      for ^$list.length -> $i {
        my N-GObject $object = nativecast( N-GObject, $list.nth($i));
  note "o; ", $object.raku(), ', ', $type.name_from_instance($object), ', ', ;

        my Int $count = 0;
        my Str $widget-path = '';
        my N-GObject $no-widget-path = _get_path($object);
        while my Str $oname = _iter_get_name( $no-widget-path, $count++) {
          $widget-path ~= "-$oname";
        }
  note "widget path: $widget-path";
      }
    }
  }}
    $T.set-title("Gnome::T Test");
    $T.show-all;

    diag "Test '$*PROGRAM-NAME' using '$protocol-file'";
    with $T {
      .load-test-protocol($protocol-file);
      .run-test-protocol;
    }

    diag "Done testing ...";
  }
  }}

  #-----------------------------------------------------------------------------
  has Gnome::T::Run $!run;

  #-----------------------------------------------------------------------------
  submethod new ( |c ) {
    # let the Gnome::Gtk3::Window class process the options
    self.bless( :GtkWindow, |c);
  }

  #-----------------------------------------------------------------------------
  submethod BUILD ( ) {

note "Args: $*PROGRAM-NAME, @*ARGS.raku()";

    (my $protocol-file = @*ARGS.grep(/^'--' T '='?/)) ~~ s/^'--' T '='?//;
    unless ?$protocol-file {
      $protocol-file = $*PROGRAM-NAME;
      $protocol-file ~~ s/\. \w* $/.yaml/;
    }

    my Hash $main-protocol = load-yaml($protocol-file.IO.slurp) // %();
#`{{
    with self {
      .set-title("Gnome::T Test");
      .set-position(GTK_WIN_POS_CENTER);
      .set-gravity(GDK_GRAVITY_NORTH_EAST);
      .set-size-request( 300, 200);
      .show-all;
    }
}}
    $!run .= new(:$main-protocol);
  }

  #-----------------------------------------------------------------------------
  method run-test-protocol ( ) {
    diag "Run tests ...";
    $!run.run-tests;
    diag "Done testing ...";
  }
}


#-------------------------------------------------------------------------------
# create as soon as possible to prevent start of event loop
diag "prepare tests";
my Gnome::T $T .= new;

#-------------------------------------------------------------------------------
# only after the users gui is created and displayed we can start the tests
END {
  $T.run-test-protocol;
}
