use v6;
use P5times;
use YAMLish;

#-------------------------------------------------------------------------------
unit class Gnome::T::Benchmark:auth<github:MARTIMM>;

has Hash $!tests;
has Int $!test-count;
has Int $!default-count;
has Bool $!quiet;

has Str $!project;
has Str $!project-version;
has Str $!sub-project;
has Str $!path;
has Str $!raku-version;
has Str $!test-time;

has Hash $!test-table;

#-------------------------------------------------------------------------------
submethod BUILD (
  Int:D :$!default-count = 1000, Bool :$!quiet = False,
  Str :$!project = '', Str :$!project-version, Str :$!sub-project,
  Str :$!path = '.'
) {
  $!tests = %();
  $!test-count = 0;
  $!sub-project //= $!project;
  $!project-version //= '0.0.1';
  $!raku-version = $*RAKU.compiler.version.Str;
  $!raku-version ~~ s/^ (\d+ '.' \d+ '.' \d+) .* $/$/[0].Str()/;
  $!test-time = DateTime.new(now).utc.Str;
}

#-------------------------------------------------------------------------------
method save-tests ( ) {

  if ? $!project {
    my Str $fpath = "$!path/$!project.yaml";
    $!test-table = load-yaml($fpath.IO.slurp) // %() if $fpath.IO.r;

    $!tests<test-time> = $!test-time;

    $!test-table{$!project-version}{$!raku-version}{$!sub-project} = $!tests;
    $fpath.IO.spurt(save-yaml($!test-table));
  };
}

#-------------------------------------------------------------------------------
method run-test (
  Str:D $test-text, Callable:D $test-routine, Int :$count is copy,
  Callable :$prepare, Callable :$cleanup
) {

  note "Run test $test-text";
  my Int ( $total-time, $total-utime, $total-stime) = ( 0, 0, 0);
  my ( $user1, $system1, $cuser1, $csystem1);

  $count //= $!default-count;
  loop ( my Int $test-count = 0; $test-count < $count; $test-count++ ) {
    ENTER {
      $prepare() if $prepare.defined;
      
      ( $user1, $system1, $cuser1, $csystem1) = times;
    }

    $test-routine();

    LEAVE {
      my ( $user2, $system2, $cuser2, $csystem2) = times;
      $total-utime += ($user2 - $user1);
      $total-stime += ($system2 - $system1);

      $cleanup() if $cleanup.defined;
    }
  }

  $total-time = ($total-utime + $total-stime);

  $!tests{"test$!test-count"} = %(
    :$test-text, :$count, :$total-utime, :$total-stime, :$total-time,
    :mean($total-time/$count), :rps($count/$total-time * 1e6)
  );

  $!test-count++;
}

#-------------------------------------------------------------------------------
method show-test ( Hash $test ) {

  given $test {
    note [~]
      "\n", .<test-text>, "\n  ",
      "Count:             ", .<count>, "\n  ",
      "Total user time:   ", (.<total-utime>/1e6).fmt('%.5f'), "\n  ",
      "Total system time: ", (.<total-stime>/1e6).fmt('%.5f'), "\n  ",
      "Total of both:     ", (.<total-time>/1e6).fmt('%.5f'), "\n  ",
      "Mean of both:      ", (.<mean>/1e6).fmt('%.5f'), "\n  ",
      "Runs/sec:          ", .<rps>.fmt('%.2f'), ' ',
        (.<speedup>//0.0).fmt('%.2f'), ' times faster'
  }
}

#-------------------------------------------------------------------------------
method md-test-table (
  Str $project-version, Str $raku-version, Str $sub-project, *@test-idxs
) {
  my Str $fpath = "$!path/$!project.md";
  my Bool $first = True;
  my Str $md = "|Project Version|Raku Version|Project|Sub Project|Test|Mean|Rps|Speedup|\n";
  $md ~= "|-|-|-|-|-|-|-|-|\n";

  my Hash $tests = $!test-table{$project-version}{$raku-version}{$sub-project};

  for @test-idxs -> Int $test-index {
    given $tests{"test$test-index"} {
      if $first {
        $md ~= "|$project-version|$raku-version|$!project|$sub-project|";
        $first = False;
      }
      else {
        $md ~= "|||||";
      }

      $md ~= ( .<test-text>, (.<mean>/1e6).fmt('%.5f'), .<rps>.fmt('%.2f'),
               .<speedup>.fmt('%.2f'), "\n"
             ).join('|');
    }
  }

  note $md;
}

#-------------------------------------------------------------------------------
method compare-tests ( ) {

  my @data := [$!tests.values];

  my $slowest;
  my $speedup;
  for (|@data).sort( -> $a, $b { $a<rps> <=> $b<rps> }) -> Hash $x {
    if $slowest.defined {
      $speedup = $x<rps> / $slowest;
    }

    else {
      $speedup = 0e0;
      $slowest = $x<rps>;
    }

    $x<speedup> = $speedup;
    self.show-test($x);
  }
}
