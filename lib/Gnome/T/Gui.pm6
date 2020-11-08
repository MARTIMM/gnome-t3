use v6;
use Test;
use NativeCall;

use YAMLish;
use Gnome::N::X;

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

has Any $!test-value;

#-------------------------------------------------------------------------------
submethod BUILD ( ) { }

#-------------------------------------------------------------------------------
method load-test-protocol ( Str $protocol-file ) {

  $!protocol = load-yaml($protocol-file.IO.slurp);
#note $!protocol.gist;
}

#-------------------------------------------------------------------------------
method set-top-widget ( $!top-widget ) {
  $!top-widget.show-all;
}

#-------------------------------------------------------------------------------
method run-test-protocol ( ) {

#Gnome::N::debug(:on);
  my Promise $p = $!top-widget.start-thread( self, 'run-tests', :new-context);

  # start the main loop on the main thread
  Gnome::Gtk3::Main.new.gtk-main;

  # wait for the end and show result
  await $p;
#Gnome::N::debug(:off);
}

#-------------------------------------------------------------------------------
method run-tests ( --> Str ) {

  my Int $executed-tests = 0;
  my $main = Gnome::Gtk3::Main.new;

  if $!protocol.elems {

    my Bool $ignore-wait = False;
    my $step-wait = 0.0;

    for @$!protocol -> Hash $substep {
note "SS: $substep.gist()";

      if $substep.value() ~~ Block {
        diag "substep: $substep.key() => Code block";
      }

      elsif $substep.value() ~~ List {
        diag "substep: $substep.key() => ";
        for @($substep.value()) -> $v {
          diag "           $v.key() => $v.value()";
        }
      }

      else {
        if $substep.key() eq 'step-wait' and $ignore-wait {
          diag "substep: $substep.key() => $substep.value() (ignored)";
        }

        else {
          diag "substep: $substep.key() => $substep.value()";
        }
      }

      given $substep.key {
        when 'emit-signal' {
          my Hash $ss = %(|$substep.value);
          my Str $signal-name = $ss<signal-name> // 'clicked';
          my $widget = self!get-widget($ss);
          $widget.emit-by-name( $signal-name, $widget);
        }

        when 'get-text' {
          my Hash $ss = %(|$substep.value);
          my $widget = self!get-widget($ss);
          my Gnome::Gtk3::TextBuffer $buffer .= new(
            :native-object($widget.get-buffer)
          );

          my Gnome::Gtk3::TextIter $start = $buffer.get-start-iter;
          my Gnome::Gtk3::TextIter $end = $buffer.get-end-iter;

          $!test-value = $buffer.get-text( $start, $end, 1);
        }

        when 'set-text' {
          my Hash $ss = %(|$substep.value);
          my Str $text = $ss<text>;
          my $widget = self!get-widget($ss);

          my $n-buffer = $widget.get-buffer;
          my Gnome::Gtk3::TextBuffer $buffer .= new(:native-object($n-buffer));
          $buffer.set-text($text);
          $widget.queue-draw;
        }

        when 'do-test' {
          next unless $substep.value ~~ Block;
          $executed-tests++;
          $substep.value()();
        }

        when 'get-main-level' {
          $!test-value = $main.gtk-main-level;
        }

        when 'step-wait' {
          $step-wait = $substep.value();
        }

        when 'ignore-wait' {
          $ignore-wait = ?$substep.value();
        }

        when 'wait' {
          sleep $substep.value() unless $ignore-wait;
        }

        when 'debug' {
          Gnome::N::debug(:on($substep.value));
        }

        when 'finish' {
          last;
        }
      }

      sleep($step-wait)
        unless ( $substep.key eq 'wait' or $ignore-wait or $step-wait == 0.0 );

      # make sure things get displayed
      while $main.gtk-events-pending { $main.new.iteration-do(False);
      }

      # Stop when loop is exited
      #last unless $main.gtk-main-level();
    }

    # End the main loop
    $main.gtk-main-quit() if $main.gtk-main-level();
    while $main.gtk-events-pending() { $main.iteration-do(False); }
  }


  diag "Nbr steps: {$!protocol.elems // 0}";
  diag "Nbr executed code blocks: $executed-tests";

  "Done testing"
}

#-------------------------------------------------------------------------------
method !get-widget ( Hash $opts --> Any ) {
  my Str:D $id = $opts<widget-id>;
  my Str:D $class = $opts<widget-class>;

  require ::($class);
  my $widget = ::($class).new(:build-id($id));
  is $widget.^name, $class, "Id '$id' of class $class found and initialized";

  $widget
}
