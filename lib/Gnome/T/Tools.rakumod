use v6;

use Gnome::N::N-GObject;
#use Gnome::N::GlibToRakuTypes;
#use Gnome::N::NativeLib;

use Gnome::Gtk3::Window;

#-------------------------------------------------------------------------------
unit class Gnome::T::Tools:auth<github:MARTIMM>:ver<0.1.0>;

#-------------------------------------------------------------------------------
my Gnome::T::Tools $instance;
has Gnome::Gtk3::Window $!app-window;

#-------------------------------------------------------------------------------
method new (  ) { !!! }

#-------------------------------------------------------------------------------
method instance ( --> Gnome::T::Tools ) {
  $instance // self.bless;
}

#-------------------------------------------------------------------------------
method set-app-window ( Gnome::Gtk3::Window:D $!app-window ) { }

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
