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

  my Str $image-dir = $step<image-dir> // Str;
  my Str $image-file = $step<image-file> // $widget-name;
  my Str $image-type = $step<image-type> // 'png';

  $image-file ~= ".$image-type" unless $image-file ~~ m/ \. [ png || jpg ] /;
  $image-file = "$image-dir/$image-file" if $image-dir;

  $*log-file-handle.print("  store in $image-file\n");
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

    $*log-file-handle.print("  $e.message()\n") if $e.is-valid;
    diag $e.message if $e.is-valid;
  }

  $cairo-context.clear-object;
  $surface.clear-object;
  $widget.clear-object if $widget.is-valid;
}



=finish
#-------------------------------------------------------------------------------
sub _gtk_widget_draw (
  N-GObject $widget, cairo_t $cr
) is native(&gtk-lib)
  is symbol('gtk_widget_draw')
  { * }

sub _cairo_create (
  cairo_surface_t $target --> cairo_t
) is native(&cairo-lib)
  is symbol('cairo_create')
  { * }
