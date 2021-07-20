#!/usr/bin/env -S raku

use v6;
use MONKEY-SEE-NO-EVAL;

=begin comment :Gnome-T
my Int $i = 10;
my Int $j = 10;

note "$?LINE, {$i + $j}";
=end comment


=begin comment
my Int $i = 10;
my Int $j = 10;
=end comment

#dd $=pod;
#print "\n";

for @$=pod -> $pblock {
  next unless $pblock ~~ Pod::Block::Comment;
  next unless $pblock.config<Gnome-T>;

#  note "P: \n", $pblock.config;
  note "Eval code \n", $pblock.contents[0..*-1].join('');
  note "\nrun;\n";
  EVAL($pblock.contents[0..*-1].join(''));
}


#`{{

in Gnome::T
- search for comment blocks with config key
- get the text from the blocks
- problem;
    how to inject the code at the proper location in the running code. It
    must be run at the location of the comment block.

}}
