use v6;
use Test;
use NativeCall;

use YAMLish;
use Gnome::N::X;

use Gnome::N::N-GObject;

use Gnome::Cairo::ImageSurface;
#use Gnome::Cairo;
#use Gnome::Cairo::Types;
use Gnome::Cairo::Enums;

use Gnome::Gtk3::Main;
use Gnome::Gtk3::TextIter;
use Gnome::Gtk3::TextBuffer;
use Gnome::Gtk3::TextView;
use Gnome::Gtk3::Widget;

use Gnome::Gdk3::Window;
use Gnome::Gdk3::Pixbuf;

use Gnome::Glib::Error;

#-------------------------------------------------------------------------------
=begin pod

=end pod

#-------------------------------------------------------------------------------
unit class Gnome::T:auth<github:MARTIMM>:ver<0.5.0>;

#-------------------------------------------------------------------------------
my Gnome::T $instance;

#has Gnome::Cairo::ImageSurface $!surface;
has Gnome::Gdk3::Window $!gdk-window;

has Str $!protocol-name;
has Array $!protocol;
has $!top-widget;
has Hash $!widgets;
has Hash $!sandbox = %();

#-------------------------------------------------------------------------------
method new ( ) { !!! }

#-------------------------------------------------------------------------------
submethod BUILD ( Str :$protocol-name, Str :$dir is copy, Hash :$widgets ) {
  $!sandbox = %();
  $!widgets = %();
#`{{
  if ?$protocol-name {
    $!protocol-name = $protocol-name;

    $dir //= '.';

    if "$dir/$!protocol-name.yaml".IO ~~ :r {
      $!protocol = load-yaml("$dir/$!protocol-name.yaml".IO.slurp) // [];
    }

    elsif "$dir/$!protocol-name.yml".IO ~~ :r {
      $!protocol = load-yaml("$dir/$!protocol-name.yml".IO.slurp) // [];
    }

    else {
      $!protocol = [];
    }

    $!widgets = $widgets // %();

    my Gnome::Gtk3::Widget $w .= new(:native-object($!widgets.values[0][1]));
    $!top-widget = $w.get-toplevel-rk;
    $!gdk-window .= new(:native-object($!top-widget.get-window));
  }
}}
}

#-------------------------------------------------------------------------------
method instance ( |c ) {
  $instance //= self.bless(|c);
  $instance
}

#-------------------------------------------------------------------------------
method load-test-protocol ( Str:D $protocol-file where *.IO.r ) {
  $!protocol-name = $protocol-file.IO.basename;
  $!protocol-name ~~ s/ \. [ yaml | yml ] //;

  $!protocol = load-yaml($protocol-file.IO.slurp) // [];
#note $!protocol.gist;
}

#-------------------------------------------------------------------------------
method !load-subtest-protocol ( Str:D $protocol-file --> List ) {
  my $protocol-name = $protocol-file.IO.basename;
  $protocol-name ~~ s/ \. [ yaml | yml ] //;

  my Array $protocol = load-yaml($protocol-file.IO.slurp) // [];

  ( $protocol-name, $protocol)
}

#-------------------------------------------------------------------------------
method set-widgets-table ( Hash $!widgets ) {
  # get some widget from the table and get the top-level window
  my Gnome::Gtk3::Widget $w .= new(:native-object($!widgets.values[0][1]));
  $!top-widget = $w.get-toplevel-rk;
  $!gdk-window .= new(:native-object($!top-widget.get-window));

#  $!top-widget.show-all;
}

#-------------------------------------------------------------------------------
method add-widgets-table ( Hash $widgets ) {
  for $widgets.kv -> $k, $v {
    note "key '$k' already used in widgets table, widget entry is ignored"
      if $!widgets{$k};
    $!widgets{$k} = $v;
  }
}

#-------------------------------------------------------------------------------
#method set-top-widget ( Str:D $top-widget-name ) {
#  $!top-widget = self!get-widget($top-widget-name);
#  die "Top widget not found in widget table" unless ?$top-widget-name;
#
#  $!top-widget.show-all;
#}

#-------------------------------------------------------------------------------
method run-test-protocol ( ) {

#Gnome::N::debug(:on);
  #my Promise $p = $!top-widget.start-thread( self, 'run-tests', :new-context);
  my Gnome::Gtk3::Widget $w .= new(:native-object($!widgets.kv[0][1]));
  my Promise $p = $w.start-thread(
    self, 'run-tests', :new-context, :$!protocol, :$!protocol-name, :top-level
  );

  # start the main loop on the main thread
  my Gnome::Gtk3::Main $main .= new;
  $main.main unless $main.level;

  # wait for the end and show result
  await $p;
#  is $p.result, 'Done testing', 'Finished with test protocol';

#  self.run-tests;
  done-testing;
#Gnome::N::debug(:off);

  # quit all remaining loop levels
  while $main.level {
    note "level: $main.level()";
    $main.quit;
    while $main.events-pending { $main.iteration-do(False); }
  }
}

#-------------------------------------------------------------------------------
method run-tests (
  Array :$protocol, Str :$protocol-name, Bool :$top-level = False
) {
  CONTROL { when CX::Warn {  note .gist; .resume; } }

  my Bool $verbose = True;

  diag "prepare tests";

  my Int $executed-tests = 0;
  my $main = Gnome::Gtk3::Main.new;

  my Bool $ignore-wait = False;
  my $step-wait = 0.0;

#  my Hash $!sandbox = %();

  # process all steps
  for @$protocol -> Hash $step {
#    diag "Test step: $step<type>";

    given $step<type> {

      when 'configure-wait' {
        $ignore-wait = $step<ignore-wait> // False;
        $step-wait = $step<step-wait> // 0.0;

        diag "$step<type>: ignore = $ignore-wait, wait = $step-wait sec";
      }

      when 'emit-signal' {
        my Str $widget-name = $step<widget-name> // '';
        my Str $signal-name = $step<signal-name>;

        if !$widget-name or !$signal-name {
          diag "$step<type>: widget-name and/or signal-name not defined, test skipped";
          next;
        }

        diag "$step<type>: name = $widget-name, signal = $signal-name";

        my $widget = self!get-widget($widget-name);
        $widget.emit-by-name( $signal-name, $widget);
#        sleep(0.5);
      }

      when 'get-text' {
        my Str $widget-name = $step<widget-name> // '';
        my Str $value-key = $step<value-key> // '';

        if !$value-key or !$widget-name {
          diag "$step<type>: value-key and/or widget-name not defined, test skipped";
          next;
        }

        my $widget = self!get-widget($widget-name);
        my Gnome::Gtk3::TextBuffer $buffer .= new(
          :native-object($widget.get-buffer)
        );
        my Gnome::Gtk3::TextIter $start = $buffer.get-start-iter;
        my Gnome::Gtk3::TextIter $end = $buffer.get-end-iter;

        $!sandbox{$value-key} = $buffer.get-text( $start, $end, 1);

        my $s = $!sandbox{$value-key};
        $s ~~ s:g/\n/␤/;
        diag "$step<type>: text = '$s'";
      }

      when 'get-value' {
        my Str $widget-name = $step<widget-name> // '';
        my Str $method-name = $step<method-name> // '';
        my Str $value-key = $step<value-key> // '';

        if !$value-key or !$widget-name or !$method-name {
          diag "$step<type>: value-key, widget-name and/or method-name not defined, test skipped";
          next;
        }

        my $widget = self!get-widget($widget-name);
        diag "$step<type>: name = $widget-name, method = $method-name";

        $!sandbox{$value-key} = $widget."$method-name"();
#note "Sbox: $value-key, $!sandbox{$value-key}";
      }

      when 'finish' {
        diag "$step<type>: exit test protocol";
        last;
      }

#      when 'get-main-level' {
#        $test-value = $main.gtk-main-level;
#      }

#`{{
      when 'verbose' {
        $verbose = True;
      }

      when 'quiet' {
        $verbose = False;
      }
}}

      when 'set-text' {
        my Str $widget-name = $step<widget-name> // '';
        if !$widget-name {
          diag "$step<type>: widget-name not defined, test skipped";
          next;
        }

        my $widget = self!get-widget($widget-name);
        my Gnome::Gtk3::TextBuffer $buffer .= new(
          :native-object($widget.get-buffer)
        );

        my $s = $step<text> // '';
        $s ~~ s:g/\n/␤/;
        diag "$step<type>: text = '$s'";

        $buffer.set-text($step<text> // '');
        $widget.queue-draw;
      }

      when 'snapshot' {
        my Str $widget-name = $step<widget-name> // '';
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
          $image-file = "$image-dir/$protocol-name.$image-type";
        }

        my $widget = self!get-widget($widget-name);

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
      }

      when 'sub-tests' {
        my Str $protocol-file = $step<protocol-file>;
        if $protocol-file.IO !~~ :r {
          diag "$step<type>: protocol-file not found, test skipped";
          next;
        }

        #diag "$step<type>: sub protocol from $protocol-file";
        my ( $pname, $p) = self!load-subtest-protocol($protocol-file);
        subtest $pname, {
          self.run-tests( :protocol($p), :protocol-name($pname));
        }
        $executed-tests++;
      }

      when 'wait' {
        $step-wait = $step<step-wait> // 1.0;
        diag "$step<type>: wait for $step-wait sec";
        sleep($step-wait) unless $ignore-wait or $step-wait == 0.0;
      }
    }

    # perform test if any
    if ?$step<test> {
      $executed-tests++;
      given $step<test>[0] {
        when 'is' {
          my $result = $!sandbox{$step<test>[1]} // '';
          #my $s = $result;
          #$s ~~ s:g/\n/␤/;
          my $check-with = $step<test>[2] // '';
          my Str $note = $step<test>[3] // '';
          #diag "test: $step<test>[0] '$s'";
          is $result, $check-with, $note;
        }

        default {
          # not a recognized test
          $executed-tests--;
        }
      }
    }

    # loop wait unless wait is to be ignored or wait time is 0
    unless $ignore-wait or $step-wait == 0.0 {
      sleep($step-wait);
    }

    # make sure things get displayed
    while $main.events-pending { $main.new.iteration-do(False); }
  }

  # End the main loop
#  $main.quit if $main.level;
#  while $main.events-pending { $main.iteration-do(False); }

#  sleep(0.5);
  diag "Nbr steps in $protocol-name: {$protocol.elems // 0}";
  diag "Nbr executed tests: $executed-tests";

#`{{
note 'tl: ', $top-level;
note "level: $main.level()";
  if $top-level {
    # quit all remaining loop levels
    while $main.level {
      note "level: $main.level()";
      $main.quit;
      while $main.events-pending { $main.iteration-do(False); }
    }
  }
}}
}

#-------------------------------------------------------------------------------
method !get-widget ( Str $widget-name --> Any ) {

  my List $widget-descr = $!widgets{$widget-name};
  my Str $class-name = $widget-descr[0];
  my  $native-object = $widget-descr[1];
  require ::($class-name);
  ::($class-name).new(:$native-object)
}

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
#---[ init ]--------------------------------------------------------------------
#-------------------------------------------------------------------------------
