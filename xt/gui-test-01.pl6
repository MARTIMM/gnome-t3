use v6;

use Gnome::T::Gui;

use Gnome::Gtk3::Main;
use Gnome::Gtk3::Builder;
use Gnome::Gtk3::Window;
use Gnome::Gtk3::TextIter;
use Gnome::Gtk3::TextBuffer;
use Gnome::Gtk3::TextView;

#-------------------------------------------------------------------------------
class Handlers {

  has Gnome::Gtk3::Main $!main;
  has Gnome::Gtk3::TextBuffer $!text-buffer;
  has Gnome::Gtk3::TextView $!text-view;

  #-----------------------------------------------------------------------------
  method glade-get-text ( Str:D $id --> Str ) {

    $!text-view .= new(:build-id($id));
    $!text-buffer .= new(:native-object($!text-view.get-buffer));

    my Gnome::Gtk3::TextIter $start = $!text-buffer.get-start-iter;
    my Gnome::Gtk3::TextIter $end = $!text-buffer.get-end-iter;

    $!text-buffer.get-text( $start, $end)
  }

  #-----------------------------------------------------------------------------
  method glade-set-text ( Str:D $id, Str:D $text ) {

    $!text-view .= new(:build-id($id));
    $!text-buffer .= new(:native-object($!text-view.get-buffer));
    $!text-buffer.set-text($text);
  }

  #-----------------------------------------------------------------------------
  method glade-add-text ( Str:D $id, Str:D $text is copy ) {

    $!text-view .= new(:build-id($id));
    $!text-buffer .= new(:native-object($!text-view.get-buffer));

    my Gnome::Gtk3::TextIter $start = $!text-buffer.get-start-iter;
    my Gnome::Gtk3::TextIter $end = $!text-buffer.get-end-iter;

    $text = $!text-buffer.get-text( $start, $end, 1) ~ $text;
    $!text-buffer.set-text($text);
  }

  #-----------------------------------------------------------------------------
  # Get the text and clear text field. Returns the original text
  method glade-clear-text ( Str:D $id --> Str ) {

    $!text-view .= new(:build-id($id));
    $!text-buffer .= new(:native-object($!text-view.get-buffer));

    my Gnome::Gtk3::TextIter $start = $!text-buffer.get-start-iter;
    my Gnome::Gtk3::TextIter $end = $!text-buffer.get-end-iter;

    my Str $text = $!text-buffer.get-text( $start, $end, 1);
    $!text-buffer.set-text("");

    $text
  }



  #-----------------------------------------------------------------------------
  method exit-program ( --> Int ) {
#`{{
    diag "quit-program called";
    diag "Widget: " ~ $widget.perl if ?$widget;
    diag "Data: " ~ $data.perl if ?$data;
    diag "Object: " ~ $object.perl if ?$object;
}}
#note "LL 1c: ", gtk_main_level();
    Gnome::Gtk3::Main.new.main-quit;
#note "LL 1d: ", gtk_main_level();

    1
  }

  #-----------------------------------------------------------------------------
  method copy-text ( --> Int ) {

#note "copy text";
    my Str $text = self.glade-clear-text('inputTxt');
    self.glade-add-text( 'outputTxt', $text);

    1
  }

  #-----------------------------------------------------------------------------
  method clear-text ( --> Int ) {

#note "clear text";
    self.glade-clear-text('outputTxt');

    1
  }
}

#-------------------------------------------------------------------------------
# load interface description
my Gnome::Gtk3::Builder $gui-description .= new(
  :file<xt/Data/test-interface-01.xml>
);

# create the handlers table
my Handlers $h .= new;
my Hash $handlers = %(
  :exit-program($h),
  :copy-text($h),
  :clear-text($h),
);

# register all signals
$gui-description.connect-signals-full($handlers);

# load test protocol
my Gnome::T::Gui $gui-test .= new;
$gui-test.load-test-protocol('xt/Data/test-protocol-01.yaml');

my Gnome::Gtk3::Window $w .= new(:build-id<window>);
$gui-test.set-top-widget($w);
$gui-test.run-test-protocol;
#Gnome::Gtk3::Main.new.gtk-main;
