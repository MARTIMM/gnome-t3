#!/usr/bin/env -S raku -Ilib

use v6;

use lib 'xt/testlibs';
use GuiTest01;

#use Gnome::T::Gui;

use Gnome::Gtk3::Main;
use Gnome::Gtk3::Builder;
use Gnome::Gtk3::Window;

#-------------------------------------------------------------------------------
# load interface description
my Gnome::Gtk3::Builder $gui-description .= new(
  :file<xt/Data/test-interface-01.glade>
);

# create handlers table and register all signals
my GuiTest01 $h .= new;
$gui-description.connect-signals-full( %(
    :exit-program($h),
    :copy-text($h),
    :clear-text($h),
  )
);

my Gnome::Gtk3::Window $w .= new(
  :native-object($gui-description.get-object('window'))
);

$w.show-all;
Gnome::Gtk3::Main.new.gtk-main;
