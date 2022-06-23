use v6;
use NativeCall;
use Test;

use YAMLish;

#use Gnome::Cairo::Enums;
#use Gnome::Cairo::ImageSurface;
#use Gnome::Cairo;
#use Gnome::Cairo::Types;

use Gnome::Gtk3::Main;
use Gnome::Gtk3::Builder;
use Gnome::Gtk3::Window;
use Gnome::Gtk3::Widget;
#use Gnome::Gtk3::TextIter;
#use Gnome::Gtk3::TextBuffer;
#use Gnome::Gtk3::TextView;

#use Gnome::Gdk3::Pixbuf;
use Gnome::Gdk3::Keysyms;
use Gnome::Gdk3::Types;
use Gnome::Gdk3::Events;
use Gnome::Gdk3::Window;
use Gnome::Gdk3::Display;

#use Gnome::Glib::Error;

use Gnome::N::N-GObject;
use Gnome::N::GlibToRakuTypes;
use Gnome::N::NativeLib;
#use Gnome::N::X;

use Gnome::T::Tools;
use Gnome::T::StepWait;
use Gnome::T::StepSnapshot;

#-------------------------------------------------------------------------------
unit class Gnome::T::Run:auth<github:MARTIMM>;
also is Gnome::Gtk3::Window;

#-----------------------------------------------------------------------------
#has Gnome::Gtk3::TextBuffer $!text-buffer;
#has Gnome::Gtk3::TextIter $!start;
#has Gnome::Gtk3::TextIter $!end;

has Hash $!sandbox;
#has $!T is required;
has Bool $!verbose;

has Str $!protocol-file;
has Hash $!main-protocol;
has Array $!protocol;
has Str $!protocol-name;
has Hash $!config;

has Int $!executed-tests;

has Gnome::T::Tools $!tools;
has Gnome::T::StepWait $!step-wait;
has Gnome::T::StepSnapshot $!step-snapshot;

has Gnome::Gtk3::Main $!main;
has Gnome::Gtk3::Window $!app-window;
has Gnome::Gtk3::Builder $!builder;

#-------------------------------------------------------------------------------
submethod new ( |c ) {
  # let the Gnome::Gtk3::Window class process the options
  self.bless( :GtkWindow, |c);
}

#-------------------------------------------------------------------------------
submethod BUILD ( Str:D :$!protocol-file ) {

  $!builder .= new;
  $!builder._set-test-mode(True);

  $!main .= new;
  $!sandbox = %();

  $!main-protocol = load-yaml($!protocol-file.IO.slurp) // %();
  $!protocol = $!main-protocol<test-protocol> // [];
  $!config = $!main-protocol<config> // %();
  $!protocol-name = $!config<protocol-name> // 'gui-test';

  $!verbose = True;
  $!executed-tests = 0;

  $!tools .= instance;
  $!step-wait .= new;
  $!step-snapshot .= new;

  with self {
    .set-title("Gnome::T Test");
    .set-position(GTK_WIN_POS_CENTER);
    .set-gravity(GDK_GRAVITY_NORTH_EAST);
    .set-size-request( 300, 200);
    .show-all;
  }

#  Gnome::N::debug(:on) if $!config<debug> // False;
#note 'debug: ', $!config<debug>;

  # Note: $!app-window can not be set here because users gui is not
  # build yet and thus no objects are created
}

#`{{
#-----------------------------------------------------------------------------
method set-buffer ( Str $id ) {
  my Gnome::Gtk3::TextView $text-view .= new(:build-id($id));
  $!text-buffer .= new(:native-object($text-view.get-buffer));
  $!start = $!text-buffer.get-start-iter;
  $!end = $!text-buffer.get-end-iter;
}

#-----------------------------------------------------------------------------
method gui-set-text ( Str:D $id, Str:D $text ) {
  self.set-buffer($id);
  $!text-buffer.set-text($text);
}

#-----------------------------------------------------------------------------
method gui-get-text ( Str:D $id --> Str ) {
  self.set-buffer($id);
  $!text-buffer.get-text( $!start, $!end)
}

#-----------------------------------------------------------------------------
method gui-add-text ( Str:D $id, Str:D $text is copy ) {

  self.set-buffer($id);
  $text = $!text-buffer.get-text( $!start, $!end, 1) ~ $text;
  $!text-buffer.set-text($text);
}

#-----------------------------------------------------------------------------
# Get the text and clear text field. Returns the original text
method gui-clear-text ( Str:D $id --> Str ) {
  self.set-buffer($id);
  my Str $text = $!text-buffer.get-text( $!start, $!end, 1);
  $!text-buffer.set-text("");

  $text
}
}}

#`{{TODO review...
#-------------------------------------------------------------------------------
method !load-subtest-protocol ( Str:D $protocol-file --> List ) {
  my $!protocol-name = $protocol-file.IO.basename;
  $!protocol-name ~~ s/ \. [ yaml | yml ] //;

  my Hash $protocol = load-yaml($protocol-file.IO.slurp) // [];

  ( $!protocol-name, $protocol)
}
}}

#-------------------------------------------------------------------------------
# run after users gui is set up and made visible
method run-tests ( ) {
  CONTROL { when CX::Warn {  note .gist; .resume; } }

  # only here we can get the window object from one of the builders
  $!app-window = $!tools.get-widget($!config<app-window-id>);
  $!tools.set-app-window($!app-window);

#note $!main-protocol.raku;

  # open a logfile for the tests$
  my Str $path = $!protocol-file.IO.dirname;
#note $path;

  $*log-time .= now;
  my Str $t = $*log-time.Str();
  $t ~~ s/ \. .* $ //;
  $t ~~ s/ T / /;
  my Str $log-file-name = [~] $path, '/', $!protocol-name, ' ', $t, '.log';
  diag "Open logfile $log-file-name";
  $*log-file-handle = $log-file-name.IO.open(:rw);

  # process all steps
  for @$!protocol -> Hash $step {
    diag "\nTest step: $step<type>";
    diag "\nTest step: $step.gist()";
    $*log-file-handle.print(
      "\n$*log-time.hh-mm-ss(): Test step: $step<type>\n"
    );

    given $step<type> {
#`{{
      when 'debug-on' {
        Gnome::N::debug(:on);
      }

      when 'debug-of' {
        Gnome::N::debug(:off);
      }
}}

      when 'configure-wait' {
        $!step-wait.configure($step);
      }

      when 'wait' {
        $!step-wait.wait($step);
      }

      when 'explicit-wait' {
note "$!step-wait, $step.gist()";
        $!step-wait.explicit-wait($step);
      }

      when 'emit-signal' {
        my Str $widget-name = $step<widget-name> // '';
        my Str $widget-type = $step<widget-type> // '';
        my Str $signal-name = $step<signal-name>;

        if !$widget-name or !$signal-name {
          diag "$step<type>: widget-name and/or signal-name not defined, test skipped";
          $*log-file-handle.print(
            "  widget-name and/or signal-name not defined, test skipped\n"
          );
          next;
        }

        diag "$step<type>: name = $widget-name, signal = $signal-name";
        $*log-file-handle.print(
          "  name = $widget-name, signal = $signal-name\n"
        );

        my $widget = $!tools.get-widget( $widget-name, $widget-type);
        $widget.emit-by-name( $signal-name, $widget);
        $widget.clear-object if $widget.is-valid;
      }
#`{{
      when 'insert-event' {
        my Str $widget-name = $step<widget-name> // '';
        my Str $widget-type = $step<widget-type> // '';

        if !$widget-name {
          diag "$step<type>: widget-name, test skipped";
          $*log-file-handle.print(
            "  widget-name not defined, test skipped\n"
          );
          next;
        }

        diag "$step<type>: name = $widget-name";
        $*log-file-handle.print(
          "  name = $widget-name\n"
        );

        my $widget = $!tools.get-widget( $widget-name, $widget-type);
        my Gnome::Gdk3::Display $display = $widget.get-display-rk;
        my Gnome::Gdk3::Window $window .= new(
          :native-object($widget.get-window)
        );
note "display: $display.is-valid(), $display.get-name()";
note "window: $window.is-valid()";

        my N-GdkEvent $event;
        $event .= new(
          N-GdkEventButton.new(
            :type(GDK_BUTTON_PRESS),
            :$window,
            :send_event(1),
            :time(time),
            :x(20), :y(20), :axes(Num),
            :state(0),
            :button(1),
#            Gnome::Gdk3::Events.new.get-source-device($event),
#            :x_root(20), :y_root(20)
          )
        );
note "event: $event.gist()";

        $widget.clear-object if $widget.is-valid;
      }
}}

#`{{
      when 'get-text' {
        my Str $widget-name = $step<widget-name> // '';
        my Str $widget-type = $step<widget-type> // '';
        my Str $value-key = $step<value-key> // '';

        if !$value-key or !$widget-name {
          diag "$step<type>: value-key and/or widget-name not defined, test skipped";
          next;
        }

        my $widget = $!tools.get-widget( $widget-name, $widget-type);
        my Gnome::Gtk3::TextBuffer $buffer .= new(
          :native-object($widget.get-buffer)
        );
        my Gnome::Gtk3::TextIter $start = $buffer.get-start-iter;
        my Gnome::Gtk3::TextIter $end = $buffer.get-end-iter;

        $!sandbox{$value-key} = $buffer.get-text( $start, $end, 1);

        my $s = $!sandbox{$value-key};
        $s ~~ s:g/\n/␤/;
        diag "$step<type>: text = '$s'";

        $widget.clear-object if $widget.is-valid;
      }
}}
      when 'get-value' {
        my Str $widget-name = $step<widget-name> // '';
        my Str $widget-type = $step<widget-type> // '';
        my Str $method-name = $step<method-name> // '';
        my Str $value-key = $step<value-key> // '';

        if !$value-key or !$widget-name or !$method-name {
          diag "$step<type>: value-key, widget-name and/or method-name not defined, test skipped";
          $*log-file-handle.print(
            "  value-key, widget-name and/or method-name not defined, test skipped\n"
          );
          next;
        }

        my $widget = $!tools.get-widget( $widget-name, $widget-type);
        diag "$step<type>: name = $widget-name, method = $method-name";
        $*log-file-handle.print(
          "  name = $widget-name, method = $method-name\n"
        );

        $!sandbox{$value-key} = $widget."$method-name"();
#note "Sbox: $value-key, $!sandbox{$value-key}";
        $widget.clear-object if $widget.is-valid;
      }

      when 'finish' {
        diag "$step<type>: exit test protocol";
        $*log-file-handle.print("  exit test protocol\n");
        last;
      }

#      when 'get-main-level' {
#        $test-value = $!main.gtk-main-level;
#      }

#`{{
      when 'verbose' {
        $!verbose = True;
      }

      when 'quiet' {
        $!verbose = False;
      }
}}

#`{{
      when 'set-text' {
        my Str $widget-name = $step<widget-name> // '';
        my Str $widget-type = $step<widget-type> // '';
        if !$widget-name {
          diag "$step<type>: widget-name not defined, test skipped";
          next;
        }

        my $widget = $!tools.get-widget( $widget-name, $widget-type);
        my Gnome::Gtk3::TextBuffer $buffer .= new(
          :native-object($widget.get-buffer)
        );

        my $s = $step<text> // '';
        $s ~~ s:g/\n/␤/;
        diag "$step<type>: text = '$s'";

        $buffer.set-text($step<text> // '');
        $widget.queue-draw;
        $widget.clear-object if $widget.is-valid;
      }
}}

      when 'snapshot' {
        $!step-snapshot.shoot( $!config, $step);

#`{{
        my Str $widget-name = $step<widget-name> // '';
        my Str $widget-type = $step<widget-type> // '';
        if !$widget-name {
          diag "$step<type>: widget-name not defined, test skipped";
          next;
        }

        my Str $image-dir = $step<image-dir> // '.';
        my Str $image-file = $step<image-file> // '';
        my Str $image-type = $step<image-type> // '';
        if ?$image-file {
          $image-type //= $image-file.IO.extension;
          unless ?$image-type {
            $image-type = 'png';
            $image-file ~= ".$image-type";
          }
        }

        else {
          $image-type = 'png' unless ?$image-type;
          $image-file = "$image-dir/$!protocol-name.$image-type";
        }

        my $widget = $!tools.get-widget( $widget-name, $widget-type);

        diag "$step<type>: store snapshot in $image-file";

        my Int $width = $widget.get-allocated-width;
        my Int $height = $widget.get-allocated-height;
        my Gnome::Cairo::ImageSurface $surface .= new(
          :format(CAIRO_FORMAT_ARGB32), :$width, :$height
        );
        my Gnome::Cairo $cairo-context .= new(:$surface);
        $widget.draw($cairo-context);

        if $image-type eq 'png' {
          $surface.write-to-png($image-file);
        }

        else {
          my Gnome::Gdk3::Pixbuf $pb .= new(
            :$surface, :clipto( 0, 0, $width, $height)
          );

          my Gnome::Glib::Error $e = $pb.savev(
            $image-file, 'jpeg', ["quality",], ["100",]
          );

          diag $e.message if $e.is-valid;
        }

        $cairo-context.clear-object;
        $surface.clear-object;
        $widget.clear-object if $widget.is-valid;
}}
      }

#`{{TODO review
      when 'sub-tests' {
        my Str $protocol-file = $step<protocol-file>;
        if $protocol-file.IO !~~ :r {
          diag "$step<type>: protocol-file not found, test skipped";
          next;
        }

        #diag "$step<type>: sub protocol from $protocol-file";
        my ( $pname, $p) = self!load-subtest-protocol($protocol-file);
        subtest $pname, {
          self.run-tests( :protocol($p<test-protocol>), :protocol-name($pname));
        }
        $!executed-tests++;
      }
}}
    }

    # perform test if any
    if ?$step<test> {
      $!executed-tests++;
      given $step<test>[0] {
        when 'is' {
          my $result = $!sandbox{$step<test>[1]} // '';
          #my $s = $result;
          #$s ~~ s:g/\n/␤/;
          my $check-with = $step<test>[2] // '';
          my Str $note = $step<test>[3] // '';
          #diag "test: $step<test>[0] '$s'";
          is $result, $check-with, $note;
          $*log-file-handle.print(
            "  testing 'is $result, $check-with, $note'\n"
          );
        }

        default {
          # not a recognized test
          $*log-file-handle.print("  $step<test> is not a recognized test\n");
          $!executed-tests--;
        }
      }
    }

    # loop wait unless wait is to be ignored or wait time is 0
    $!step-wait.loop-wait;

    # make sure things get displayed
    while $!main.events-pending { $!main.new.iteration-do(False); }
  }

  # End the main loop
  $!main.quit if $!main.level;
  while $!main.events-pending { $!main.iteration-do(False); }

#  sleep(0.5);
  diag "Nbr steps in $!protocol-name: {$!protocol.elems // 0}";
  diag "Nbr executed tests: $!executed-tests";
  $*log-file-handle.print("  Nbr steps in $!protocol-name: {$!protocol.elems // 0}\n");
  $*log-file-handle.print("  Nbr executed tests: $!executed-tests\n");

#`{{
note 'tl: ', $top-level;
note "level: $!main.level()";
  if $top-level {
    # quit all remaining loop levels
    while $!main.level {
      note "level: $!main.level()";
      $!main.quit;
      while $!main.events-pending { $!main.iteration-do(False); }
    }
  }
}}

  $*log-file-handle.close;
}

#`{{
#-------------------------------------------------------------------------------
method get-widget ( Str:D $widget-name, Str $widget-type = '' --> Any ) {

  my $builder-object;
#  my Gnome::Gtk3::Builder $b = $!app-window._get-builders[0];

  # must loop over all builders available
  for @($!app-window._get-builders) -> $b {
note 'builder: ', $b.raku;
#next;
    $builder-object = $b.get-object($widget-name) // N-GObject;
    last if ?$builder-object;
  }

#  my $builder-object = $builder.get-object($widget-name);
note "$widget-name, $widget-type, $builder-object.raku()";
#my Array $bs = self.get-builders;
#note $bs;
#return;

#`{{
  my $b = self.get-builders[0];

  # must loop over all builders available
#  for @(self.get-builders) -> $b {
note 'builder: ', $b.raku;
#next;
    $builder-object = $b.get-object($widget-name) // N-GObject;
    last if ?$builder-object;
#  }
#return;
}}

  my $rk-object;
  if ?$widget-type {
    $rk-object = $!app-window._wrap-native-type-from-no(
      $builder-object, :child-type($widget-type)
    );
  }

  else {
    $rk-object = $!app-window._wrap-native-type-from-no($builder-object);
  }
note "rk object $rk-object.raku()";
  die "Native object for '$widget-name' (type '$widget-type') not found"
    unless ?$rk-object and $rk-object.is-valid;
#:child-type
#`{{
  my List $widget-descr = $!widgets{$widget-name};
  my Str $class-name = $widget-descr[0];
  my  $native-object = $widget-descr[1];
  require ::($class-name);
  ::($class-name).new(:$native-object)
}}

  $rk-object
}
}}

#`{{
#-------------------------------------------------------------------------------
method focus ( Any:D $widget ) {
  $widget.grab-focus;

  # make sure things get displayed
  while $!main.events-pending { $!main.new.iteration-do(False); }
}
}}

#`{{
#-------------------------------------------------------------------------------
method emit-keypress (
  Any:D $widget, Any:D $symbol, GdkModifierType :$modifiers?
) {
#`{{
  method handler (
    N-GdkEvent $event,
    Int :$_handle_id,
    Gnome::GObject::Object :_widget($widget),
    *%user-options
    --> Int
  );

  g_signal_emit_by_name (
    Str $detailed-signal, *@handler-arguments,
    Array :$parameters, :$return-type
  )
}}

##`{{
  my Gnome::Gtk3::Window $top-window = $!tools.get-widget('GtkWindow-0001');
note 'w: ', $top-window.raku;

  my N-GdkEvent $key-event .= new(
    :type(GDK_KEY_PRESS), :window($!app-window._get-native-object-no-reffing),
    :send_event(1), :time(time * 1000),
    :state(?$modifiers ?? $modifiers.value !! 0),
  );
  $widget.emit-by-name(
    'key-press-event', $key-event,
    :parameters([N-GdkEvent,]), :return-type(gboolean)
  );

  # make sure things get displayed
  while $!main.events-pending { $!main.new.iteration-do(False); }
#}}
}
}}

#-------------------------------------------------------------------------------
#---[ handlers ]----------------------------------------------------------------
#-------------------------------------------------------------------------------
#`{{
# Called by the draw signal after changing or uncovering the window.
method redraw ( cairo_t $n-cx --> Bool ) {

  # we have received a cairo context in which our surface must be set.
  given Gnome::Cairo.new(:native-object($n-cx)) {
    .set-source-surface( $!surface, 0, 0);

    # just repaint the whole scenery
    .paint;
    .clear-object;
  }

  True
}
}}

#-------------------------------------------------------------------------------
#--[ some necessary native subroutines ]----------------------------------------
#-------------------------------------------------------------------------------
#`{{ something for later
sub _path_to_string ( N-GObject $path --> Str )
  is native(&gtk-lib)
  is symbol('gtk_widget_path_to_string')
  { * }

# These subs belong to Gnome::Gtk3::Widget but is needed here. To avoid
# circular dependencies, the subs are redeclared here for this purpose
sub _get_path (
  N-GObject $widget --> N-GObject
) is native(&gtk-lib)
  is symbol('gtk_widget_get_path')
  { * }

# These subs belong to Gnome::Gtk3::WidgetPath but is needed here. To avoid
# circular dependencies, the subs are redeclared here for this purpose
sub _iter_get_name ( N-GObject $path, int32 $pos --> Str )
  is native(&gtk-lib)
  is symbol('gtk_widget_path_iter_get_name')
  { * }
}}
