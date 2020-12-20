use v6;
use Test;
use NativeCall;

use YAMLish;
use Gnome::N::X;

use Gnome::N::N-GObject;

use Gnome::Gtk3::Main;
use Gnome::Gtk3::TextIter;
use Gnome::Gtk3::TextBuffer;
use Gnome::Gtk3::TextView;

#-------------------------------------------------------------------------------
=begin pod

=end pod

#-------------------------------------------------------------------------------
unit class Gnome::T::Gui:auth<github:MARTIMM>;

has Array $!protocol;
has $!top-widget;
has Hash $!widgets;


#-------------------------------------------------------------------------------
submethod BUILD ( ) { }

#-------------------------------------------------------------------------------
method load-test-protocol ( Str $protocol-file ) {

  $!protocol = load-yaml($protocol-file.IO.slurp) // [];
#note $!protocol.gist;
}

#-------------------------------------------------------------------------------
method set-widgets-table ( Hash $!widgets ) { }

#-------------------------------------------------------------------------------
method set-top-widget ( Str:D $top-widget-name ) {
  $!top-widget = self!get-widget($top-widget-name);
  die "Top widget not found in widget table" unless ?$top-widget-name;

  $!top-widget.show-all;
}

#-------------------------------------------------------------------------------
method run-test-protocol ( ) {

#Gnome::N::debug(:on);
#  my Promise $p = $!top-widget.start-thread( self, 'run-tests', :new-context);

  # start the main loop on the main thread
#  Gnome::Gtk3::Main.new.gtk-main;

  # wait for the end and show result
#  await $p;
#  is $p.result, 'Done testing', 'Finished with test protocol';

  self.run-tests;
  done-testing;
#Gnome::N::debug(:off);
}

#-------------------------------------------------------------------------------
method run-tests ( --> Str ) {

  my Bool $verbose = True;
  my $test-value;

  diag "prepare tests";

  my Int $executed-tests = 0;
  my $main = Gnome::Gtk3::Main.new;

  my Bool $ignore-wait = False;
  my $step-wait = 0.0;

  # process all steps
  for @$!protocol -> Hash $step {
    diag "Test step: $step<type>";

    given $step<type> {

      when 'configure-wait' {
        $ignore-wait = $step<ignore-wait> // False;
        $step-wait = $step<step-wait> // 0.0;
      }

      when 'emit-signal' {
        my Str $widget-name = $step<widget> // '';
        my $widget = self!get-widget($widget-name);
        my Str $signal-name = $step<signal-name>;
        $widget.emit-by-name( $signal-name, $widget);
        sleep(0.5);
      }

      when 'finish' {
        last;
      }

#      when 'get-main-level' {
#        $test-value = $main.gtk-main-level;
#      }

      when 'get-text' {
        my Str $widget-name = $step<widget> // '';
        my $widget = self!get-widget($widget-name);
        my Gnome::Gtk3::TextBuffer $buffer .= new(
          :native-object($widget.get-buffer)
        );
        my Gnome::Gtk3::TextIter $start = $buffer.get-start-iter;
        my Gnome::Gtk3::TextIter $end = $buffer.get-end-iter;
        $test-value = $buffer.get-text( $start, $end, 1);
      }

#`{{
      when 'verbose' {
        $verbose = True;
      }

      when 'quiet' {
        $verbose = False;
      }
}}

      when 'set-text' {
        my Str $widget-name = $step<widget> // '';
        my $widget = self!get-widget($widget-name);
        my Gnome::Gtk3::TextBuffer $buffer .= new(
          :native-object($widget.get-buffer)
        );
        $buffer.set-text($step<text> // '');
        $widget.queue-draw;
      }

      when 'wait' {
        $step-wait = $step<step-wait> // 0.0;
        sleep($step-wait) unless $ignore-wait or $step-wait == 0.0;
      }
    }

    # perform test if any
    if ?$step<test> {
      $executed-tests++;
      given $step<test>[0] {
        when 'is' {
          is $test-value, $step<test>[1], $step<test>[2];
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
    while $main.gtk-events-pending { $main.new.iteration-do(False); }
  }

  # End the main loop
#  $main.gtk-main-quit() if $main.gtk-main-level();
  while $main.gtk-events-pending() { $main.iteration-do(False); }

#  sleep(0.5);
  diag "Nbr steps: {$!protocol.elems // 0}";
  diag "Nbr executed tests: $executed-tests";

  "Done testing"
}

#-------------------------------------------------------------------------------
method !get-widget ( Str $widget-name --> Any ) {

  my List $widget-descr = $!widgets{$widget-name};
  my Str $class-name = $widget-descr[0];
  my N-GObject $native-object = $widget-descr[1];
  require ::($class-name);
  ::($class-name).new(:$native-object)
}
