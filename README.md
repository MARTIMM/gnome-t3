![Gtk+ Raku logo][logo]


![T][travis-svg] ![A][appveyor-svg] ![L][license-svg]


[travis-svg]: https://travis-ci.org/MARTIMM/gnome-test.svg?branch=master
[travis-run]: https://travis-ci.org/MARTIMM/gnome-test

[appveyor-svg]: https://ci.appveyor.com/api/projects/status/github/MARTIMM/gnome-test?branch=master&passingText=Windows%20-%20OK&failingText=Windows%20-%20FAIL&pendingText=Windows%20-%20pending&svg=true
[appveyor-run]: https://ci.appveyor.com/project/MARTIMM/gnome-test/branch/master

[license-svg]: http://martimm.github.io/label/License-label.svg
[licence-lnk]: http://www.perlfoundation.org/artistic_license_2_0

[changes]: https://github.com/MARTIMM/gnome-test/blob/master/CHANGES.md
[logo]: https://martimm.github.io/gnome-gtk3/content-docs/images/gtk-raku.png

# Gnome::T3 - Raku Gnome Gtk Gui Testing

# Synopsis
On the command line write;
```
> raku -MGnome::T3 my-gui-program.raku --Ttest-protocol.yaml
```
where the program to test is called `my-gui-program.raku` using a test protocol described in the file `test-protocol.yaml`.


# Description

The modules in this package provide a testing framework to test graphical user interfaces build upon the Gnome gtk version 3 libraries.

## Test protocol

The test protocol describes the steps to be executed in order to test the user interface. There are step types to control the speed of testing, to send events to widgets, to test values of routines etc.

### Format

### The step types

#### Timing and control

* `configure-wait`;
* `wait`;
* `explicit-wait`;
* `finish`;

#### Events
* `emit-signal`;

#### Values
* `get-value`;

#### Files
* `snapshot`;
* `sub-tests`;

## Documentation
* [ 🔗 Website](https://martimm.github.io/gnome-gtk3/content-docs/reference-test.html)
* [ 🔗 License document][licence-lnk]
* [ 🔗 Release notes][changes]
* [ 🔗 Issues](https://github.com/MARTIMM/gnome-gtk3/issues)

<!--
* [ 🔗 Travis-ci run on master branch][travis-run]
* [ 🔗 Appveyor run on master branch][appveyor-run]
-->

# Installation
```
> zef install Gnome::T
```


# Author

Name: **Marcel Timmerman**
Github account name: **MARTIMM**


# Issues

There are always some problems! If you find one please help by filing an issue at [my Gnome::Gtk3 github project][issues].


# Attribution

* The inventors of Raku, formerly known as Perl 6, of course and the writers of the documentation which helped me out every time again and again.
* The builders of all the Gnome libraries and the documentation.
* Other helpful modules for their insight and use.

# Copyright
