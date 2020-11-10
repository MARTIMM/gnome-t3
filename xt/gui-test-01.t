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

  #-----------------------------------------------------------------------------
  method glade-get-text ( Str:D $id --> Str ) {

    my Gnome::Gtk3::TextView $text-view .= new(:build-id($id));
    my Gnome::Gtk3::TextBuffer $text-buffer .= new(
      :native-object($text-view.get-buffer)
    );

    my Gnome::Gtk3::TextIter $start = $text-buffer.get-start-iter;
    my Gnome::Gtk3::TextIter $end = $text-buffer.get-end-iter;

    $text-buffer.get-text( $start, $end)
  }

  #-----------------------------------------------------------------------------
  method glade-set-text ( Str:D $id, Str:D $text ) {

    my Gnome::Gtk3::TextView $text-view .= new(:build-id($id));
    my Gnome::Gtk3::TextBuffer $text-buffer .= new(
      :native-object($text-view.get-buffer)
    );
    $text-buffer.set-text($text);
  }

  #-----------------------------------------------------------------------------
  method glade-add-text ( Str:D $id, Str:D $text is copy ) {

    my Gnome::Gtk3::TextView $text-view .= new(:build-id($id));
    my Gnome::Gtk3::TextBuffer $text-buffer .= new(
      :native-object($text-view.get-buffer)
    );

    my Gnome::Gtk3::TextIter $start = $text-buffer.get-start-iter;
    my Gnome::Gtk3::TextIter $end = $text-buffer.get-end-iter;

    $text = $text-buffer.get-text( $start, $end, 1) ~ $text;
    $text-buffer.set-text($text);
  }

  #-----------------------------------------------------------------------------
  # Get the text and clear text field. Returns the original text
  method glade-clear-text ( Str:D $id --> Str ) {

    my Gnome::Gtk3::TextView $text-view .= new(:build-id($id));
    my Gnome::Gtk3::TextBuffer $text-buffer .= new(
      :native-object($text-view.get-buffer)
    );

    my Gnome::Gtk3::TextIter $start = $text-buffer.get-start-iter;
    my Gnome::Gtk3::TextIter $end = $text-buffer.get-end-iter;

    my Str $text = $text-buffer.get-text( $start, $end, 1);
    $text-buffer.set-text("");

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

# create tested handlers table and register all signals
my Handlers $h .= new;
$gui-description.connect-signals-full( %(
    :exit-program($h),
    :copy-text($h),
    :clear-text($h),
  )
);

# create tested widgets table
my Hash $widgets = %(
  :window( 'Gnome::Gtk3::Window', $gui-description.get-object('window')),
  :inputTxt( 'Gnome::Gtk3::TextView', $gui-description.get-object('inputTxt')),
  :outputTxt(
    'Gnome::Gtk3::TextView', $gui-description.get-object('outputTxt')
  ),
  :copyBttn( 'Gnome::Gtk3::Button', $gui-description.get-object('copyBttn')),
  :clearBttn( 'Gnome::Gtk3::Button', $gui-description.get-object('clearBttn')),
  :quitBttn( 'Gnome::Gtk3::Button', $gui-description.get-object('quitBttn')),
);

# load test protocol
given my Gnome::T::Gui $gui-test .= new {
  .load-test-protocol('xt/Data/test-protocol-01.yaml');
  .set-widgets-table($widgets);
  .set-top-widget('window');
  .run-test-protocol;
}
#Gnome::Gtk3::Main.new.gtk-main;
