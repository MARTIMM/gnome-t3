#!/usr/bin/env -S raku

use v6;

=begin Gnome-T
=begin code

my Int $i = 10;

=end code
=end Gnome-T


#
dd $=pod;
print "\n";

for @$=pod -> $pblock {
#  $pblock.name.say;
  if $pblock.name eq 'Gnome-T' {
    for $pblock.contents -> $c {
      note "\n", $c.contents[0..*-1].join('');
    }
  }
}
