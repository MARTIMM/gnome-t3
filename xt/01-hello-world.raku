use v6;
#use lib '../gnome-native/lib';
#use lib '../gnome-gobject/lib';
#use lib '../gnome-gtk3/lib';

# gui test module. Can be started with;
# raku -MGnome::T gui-program --Ttest-protocol.yaml
#use Gnome::T;

use Gnome::N::X;
Gnome::N::debug(:on);

use Gnome::Gtk3::Main;
use Gnome::Gtk3::Window;
use Gnome::Gtk3::Grid;
use Gnome::Gtk3::Button;

#-------------------------------------------------------------------------------
# Instantiate main module for UI control
my Gnome::Gtk3::Main $m .= new;

#-------------------------------------------------------------------------------
# Class to handle signals
class AppSignalHandlers {

  # Handle 'Hello World' button click
  method first-button-click ( :widget($b1), :other-button($b2) ) {
    $b1.set-sensitive(False);
    $b2.set-sensitive(True);
  }

  # Handle 'Goodbye' button click
  method second-button-click ( ) {
    $m.quit;
  }

  # Handle window managers 'close app' button
  method exit-program ( ) {
    $m.quit;
  }
}

#-------------------------------------------------------------------------------
# Create a top level window and set a title
my Gnome::Gtk3::Window $top-window .= new;
$top-window.set-title('Hello GTK!');
$top-window.set-border-width(20);

# Create a grid and add it to the window
my Gnome::Gtk3::Grid $grid .= new;
$top-window.add($grid);

# Create buttons and disable the second one
my Gnome::Gtk3::Button $button .= new(:label('Hello World'));
my Gnome::Gtk3::Button $second .= new(:label('Goodbye'));
$second.set-sensitive(False);

# Add buttons to the grid
$grid.attach( $button, 0, 0, 1, 1);
$grid.attach( $second, 0, 1, 1, 1);

# Instantiate the event handler class and register signals
my AppSignalHandlers $ash .= new;
$button.register-signal(
  $ash, 'first-button-click', 'clicked',
  :other-button($second)
);
$second.register-signal(
  $ash, 'second-button-click', 'clicked'
);

$top-window.register-signal( $ash, 'exit-program', 'destroy');

# Show everything and activate all
$top-window.show-all;

# inhibited when Gnome::T comes into the picture
$m.main;

#`{{
# << test code >>
# create tested widgets table
my Hash $widgets = %(
  :window( 'Gnome::Gtk3::Window', $top-window),
  :b1( 'Gnome::Gtk3::Button', $button),
  :b2( 'Gnome::Gtk3::Button', $second),
);

# << test code >>
# load test protocol
with my Gnome::T $gui-test .= instance {
  .load-test-protocol('xt/Data/01-hello-world.yaml');
  .set-widgets-table($widgets);
  .run-test-protocol;
}
}}
