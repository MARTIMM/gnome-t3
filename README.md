![Gtk+ Raku logo][logo]

<!--
[![Build Status](https://travis-ci.org/MARTIMM/gnome-native.svg?branch=master)](https://travis-ci.org/MARTIMM/gnome-native) [![License](http://martimm.github.io/label/License-label.svg)](http://www.perlfoundation.org/artistic_license_2_0)
-->

# Gnome::T - Raku Gnome Gtk Gui Testing

# Description

This is a project to provide a system which helps to test a GTK+ user interface build using te Raku modules **Gnome::***. It looks promising although there are several issues I have to face.

* Testing can be done using an XML file from the designer program `Glade`. Native objects can then easily be found using **Gnome::Gtk3::Builder** routines if the have an id to look up. When an application is built by creating the widgets and inserting them in containers, there will be no Builder involved and therefore no id to search for. The objects have to be searched for using something different. A name will do as long as it is unique but this is not obligatory from the GTK view as id's are.
* Test code and the application code must be separated.

# Installation

`zef install Gnome::T`


# Author

Name: **Marcel Timmerman**
Github account name: **MARTIMM**

# Issues

There are always some problems! If you find one please help by filing an issue at [my Gnome::Gtk3 github project][issues].

# Attribution

* The inventors of Raku, formerly known as Perl 6, of course and the writers of the documentation which helped me out every time again and again.
* The builders of all the Gnome libraries and the documentation.
* Other helpful modules for their insight and use.

[//]: # (---- [refs] ----------------------------------------------------------)
[changes]: https://github.com/MARTIMM/gnome-native/blob/master/CHANGES.md
[logo]: https://github.com/MARTIMM/gnome-gtk3/blob/master/docs/content-docs/images/gtk-raku.png
[issues]: https://github.com/MARTIMM/gnome-gtk3/issues
