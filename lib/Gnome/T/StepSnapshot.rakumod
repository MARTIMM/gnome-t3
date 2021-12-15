use v6;
use NativeCall;
use Test;

use Gnome::Gdk3::Pixbuf;

use Gnome::Cairo::Enums;
use Gnome::Cairo::ImageSurface;
#use Gnome::Cairo;
use Gnome::Cairo::Types;

use Gnome::Glib::Error;

use Gnome::N::N-GObject;
use Gnome::N::GlibToRakuTypes;
use Gnome::N::NativeLib;

use Gnome::T::Tools;

#-------------------------------------------------------------------------------
unit class Gnome::T::StepSnapshot;

has Gnome::T::Tools $!tools;

#-------------------------------------------------------------------------------
submethod BUILD ( ) {
  $!tools .= instance;
}

#-------------------------------------------------------------------------------
method shoot ( Hash $config, Hash $step ) {
  CONTROL { when CX::Warn {  note .gist; .resume; } }
  CATCH { .note; }

  my $protocol-name = $config<protocol-name> // 'gui-test';

  my Str $widget-name = $step<widget-name> // '';
  my Str $widget-type = $step<widget-type> // '';

  my $widget = $!tools.get-widget( $widget-name, $widget-type);

  my Str $image-dir = $step<image-dir>;
  my Str $image-file = $step<image-file> // $widget-name;
  my Str $image-type = $step<image-type>;

  $image-file ~= ".$image-type" if $image-type;
  $image-file = "$image-dir/$image-file" if $image-dir;

  diag "$step<type>: store snapshot in $image-file";

  my Int $width = $widget.get-allocated-width;
  my Int $height = $widget.get-allocated-height;
  my Gnome::Cairo::ImageSurface $surface .= new(
    :format(CAIRO_FORMAT_ARGB32), :$width, :$height
  );

  my Gnome::Cairo $cairo-context .= new(:$surface);
note "$?LINE, $surface.raku(), $cairo-context.raku()";
  #$widget.draw($cairo-context);
  _gtk_widget_draw(
    $widget._get-native-object-no-reffing,
    $cairo-context._get-native-object-no-reffing
  );
note "$?LINE, draw";

  if $image-type eq 'png' {
    $surface.write-to-png($image-file);
note "$?LINE";
  }

  else {
    my Gnome::Gdk3::Pixbuf $pb .= new(
      :$surface, :clipto( 0, 0, $width, $height)
    );
note "$?LINE";

    my Gnome::Glib::Error $e = $pb.savev(
      $image-file, 'jpeg', ["quality",], ["100",]
    );
note "$?LINE";

    diag $e.message if $e.is-valid;
  }

  $cairo-context.clear-object;
note "$?LINE";
  $surface.clear-object;
note "$?LINE";
  $widget.clear-object if $widget.is-valid;
note "$?LINE";
}

#-------------------------------------------------------------------------------
sub _gtk_widget_draw (
  N-GObject $widget, cairo_t $cr
) is native(&gtk-lib)
  is symbol('gtk_widget_draw')
  { * }
