use v6;

#-------------------------------------------------------------------------------
unit class GuiTest01;

use Gnome::Gtk3::Main;
use Gnome::Gtk3::Builder;
use Gnome::Gtk3::Window;
use Gnome::Gtk3::TextIter;
use Gnome::Gtk3::TextBuffer;
use Gnome::Gtk3::TextView;

#-----------------------------------------------------------------------------
has Gnome::Gtk3::TextBuffer $!text-buffer;
has Gnome::Gtk3::TextIter $!start;
has Gnome::Gtk3::TextIter $!end;

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

#-----------------------------------------------------------------------------
#----[ handlers ]-------------------------------------------------------------
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
