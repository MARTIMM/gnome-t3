use v6;

use Gnome::Gtk3::Main;
use Gnome::Gtk3::Builder;
use Gnome::Gtk3::Window;
use Gnome::Gtk3::TextIter;
use Gnome::Gtk3::TextBuffer;
use Gnome::Gtk3::TextView;

#-------------------------------------------------------------------------------
class GuiTest01 {

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
    Gnome::Gtk3::Main.new.main-quit;

    1
  }

  #-----------------------------------------------------------------------------
  method copy-text ( --> Int ) {

    my Str $text = self.glade-clear-text('inputTxt');
    self.glade-add-text( 'outputTxt', $text);

    1
  }

  #-----------------------------------------------------------------------------
  method clear-text ( --> Int ) {

    self.glade-clear-text('outputTxt');

    1
  }
}
