use v6;
use Test;

#-------------------------------------------------------------------------------
unit class Gnome::T3::StepWait;

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

  diag "$step<type>: ignore wait = $!ignore-wait, wait = $!step-wait sec";
  $*log-file-handle.print("  ignore wait = $!ignore-wait, wait = $!step-wait sec\n");
}

#-------------------------------------------------------------------------------
method wait ( Hash $step ) {
  unless $!ignore-wait or $!step-wait == 0.0 {
    $!step-wait = $step<step-wait> // 1.0;
    diag "$step<type>: wait for $!step-wait sec";
    $*log-file-handle.print("  wait for $!step-wait sec\n");
    sleep($!step-wait);
  }
}

#-------------------------------------------------------------------------------
method explicit-wait ( Hash $step ) {
  $!step-wait = $step<step-wait> // $!step-wait // 1.0;
  diag "$step<type>: wait for $!step-wait sec";
  $*log-file-handle.print("  explicit wait for $!step-wait sec\n");
  sleep($!step-wait);
}

#-------------------------------------------------------------------------------
method loop-wait ( ) {
  unless $!ignore-wait or $!step-wait == 0.0 {
    sleep($!step-wait);
  }
}
