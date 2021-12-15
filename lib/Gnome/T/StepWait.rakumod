use v6;
use Test;

#-------------------------------------------------------------------------------
unit class Gnome::T::StepWait;

#-------------------------------------------------------------------------------
has Bool $!ignore-wait;
has Rat $!step-wait;
#has Hash $!config;

#-------------------------------------------------------------------------------
submethod BUILD ( ) {
  $!ignore-wait = False;
  $!step-wait = 0.0;
}

#-------------------------------------------------------------------------------
method configure ( Hash $step ) {
  $!ignore-wait = $step<ignore-wait> // False;
  $!step-wait = $step<step-wait> // 0.0;

  diag "$step<type>: ignore = $!ignore-wait, wait = $!step-wait sec";
}

#-------------------------------------------------------------------------------
method wait ( Hash $step ) {
  $!step-wait = $step<step-wait> // 1.0;
  diag "$step<type>: wait for $!step-wait sec";
  sleep($!step-wait) unless $!ignore-wait or $!step-wait == 0.0;
}

#-------------------------------------------------------------------------------
method loop-wait ( ) {
  unless $!ignore-wait or $!step-wait == 0.0 {
    sleep($!step-wait);
  }
}
