use v6;

use Gnome::N::X;
Gnome::N::debug(:on);

use Gnome::Gtk3::Builder;

use Gnome::Gtk3::Main;
use Gnome::Gtk3::Builder;
use Gnome::Gtk3::Window;
use Gnome::Gtk3::TextIter;
use Gnome::Gtk3::TextBuffer;
use Gnome::Gtk3::TextView;

#-------------------------------------------------------------------------------
# Instantiate main module for UI control
my Gnome::Gtk3::Main $m .= new;

#----[ handler class ]----------------------------------------------------------
class TestHandlers {

  #-----------------------------------------------------------------------------
  has Gnome::Gtk3::TextBuffer $!text-buffer;
  has Gnome::Gtk3::TextIter $!start;
  has Gnome::Gtk3::TextIter $!end;

  #-----------------------------------------------------------------------------
  method exit-program ( ) {
    Gnome::Gtk3::Main.new.main-quit;
  }

  #-----------------------------------------------------------------------------
  method copy-text ( ) {
    my Str $text = self.gui-clear-text('inputTxt');
    self.gui-add-text( 'outputTxt', $text);
  }

  #-----------------------------------------------------------------------------
  method clear-text ( ) {
    self.gui-clear-text('outputTxt');
  }

  #-----------------------------------------------------------------------------
  method set-buffer ( Str $id ) {
    my Gnome::Gtk3::TextView $text-view .= new(:build-id($id));
    $!text-buffer .= new(:native-object($text-view.get-buffer));
    $!start = $!text-buffer.get-start-iter;
    $!end = $!text-buffer.get-end-iter;
  }

  #-----------------------------------------------------------------------------
  method gui-set-text ( Str:D $id, Str:D $text ) {
    self.set-buffer($id);
    $!text-buffer.set-text($text);
  }

  #-----------------------------------------------------------------------------
  method gui-get-text ( Str:D $id --> Str ) {
    self.set-buffer($id);
    $!text-buffer.get-text( $!start, $!end)
  }

  #-----------------------------------------------------------------------------
  method gui-add-text ( Str:D $id, Str:D $text is copy ) {

    self.set-buffer($id);
    $text = $!text-buffer.get-text( $!start, $!end, 1) ~ $text;
    $!text-buffer.set-text($text);
  }

  #-----------------------------------------------------------------------------
  # Get the text and clear text field. Returns the original text
  method gui-clear-text ( Str:D $id --> Str ) {
    self.set-buffer($id);
    my Str $text = $!text-buffer.get-text( $!start, $!end, 1);
    $!text-buffer.set-text("");

    $text
  }
}

my TestHandlers $th .= new;

#-------------------------------------------------------------------------------
# load interface description
my Gnome::Gtk3::Builder $gui-description .= new(
  :file<xt/Data/test-interface-01.glade>
);

# create handlers table and register all signals
$gui-description.connect-signals-full( %(
    :exit-program($th),
    :copy-text($th),
    :clear-text($th),
  )
);

my Gnome::Gtk3::Window $w .= new(
  :native-object($gui-description.get-object('window'))
);

$w.show-all;

# inhibited when Gnome::T comes into the picture
$m.main;


#`{{
# << test code >>
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

# << test code >>
# load test protocol
given my Gnome::T $gui-test .= instance {
  .load-test-protocol('xt/Data/test-protocol-01.yaml');
  .set-widgets-table($widgets);
  .run-test-protocol;
}
}}
