use v6;
use P5times;
use YAMLish;
use JSON::Fast;

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
  $!raku-version = 'Raku-' ~ $!raku-version;
  $!test-time = DateTime.new(now).utc.Str;
}

#-------------------------------------------------------------------------------
method load-tests ( ) {

  if ? $!project {
    my Str $fpath = "$!path/$!project.yaml";
    $!test-table = load-yaml($fpath.IO.slurp) // %() if $fpath.IO.r;
  };
}

#-------------------------------------------------------------------------------
method modify-tests ( ) {

  if ? $!project {
    $!tests<test-time> = $!test-time;
    $!test-table{$!raku-version}{$!project-version}{$!sub-project} = $!tests;
  };
}

#-------------------------------------------------------------------------------
method save-tests ( ) {

  if ? $!project {
    my Str $fpath = "$!path/$!project.yaml";
    $fpath.IO.spurt(save-yaml($!test-table)) if ?$!test-table;
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
method search-compare-tests (
  Str :$raku-version = Str, Str :$project-version = Str,
  Str :$sub-project = Str, Str :$test-text = Str,
  Bool :$tables = False, Bool :$markdown = True, Callable :$user-sub
) {
  my @tests = ();

  for $!test-table.keys -> $v-raku {
    if !$raku-version or (?$raku-version and $v-raku ~~ m/$raku-version/) {

      for $!test-table{$v-raku}.keys -> $v-project {
        if !$project-version or (
          ?$project-version and $v-project ~~ m/$project-version/
        ) {

          for $!test-table{$v-raku}{$v-project}.keys -> $v-subproj {
            if !$sub-project or (
              ?$sub-project and $v-subproj ~~ m/$sub-project/
            ) {

              for $!test-table{$v-raku}{$v-project}{$v-subproj}.keys -> $test {
                next if $test eq 'test-time';

                if !$test-text or (?$test-text and $!test-table{$v-raku}{$v-project}{$v-subproj}{$test}<test-text> ~~ m/$test-text/) {

                  @tests.push: [
                    $v-raku, $v-project, $v-subproj, $test,
                    $!test-table{$v-raku}{$v-project}{$v-subproj}{$test}
                  ];
                }
              }
            }
          }
        }
      }
    }
  }

  self!compare-tests( @tests, :$tables, :$markdown, :$user-sub);
}

#-------------------------------------------------------------------------------
method meta6-version ( --> Str ) {
  my Str $version = '';

  if 'META6.json'.IO.r {
    my Hash $meta6 = from-json('META6.json'.IO.slurp);
    $version = $meta6<name> ~ '-' ~ $meta6<version>;
  }

  $version
}

#-------------------------------------------------------------------------------
method type-version ( \type --> Str ) {
  my Str $t = type.perl;
  $t ~~ s:g/ <-[:]>+ '::' //;
  my Str $version = $t ~ '-' ~ (type.^ver // '0.0.0').Str;

  $version
}

#-------------------------------------------------------------------------------
method !compare-tests (
  @data? is copy, Bool :$tables = False, Bool :$markdown = True,
  Callable :$user-sub
) {

  my Str $md;
  if $markdown {
    $md = "|Raku Version|Project Version|Sub Project|Test|Mean|Rps|Speedup|\n";
    $md ~= "|-|-|-|-|-|-|-|\n";
  }

  my $slowest;
  my $speedup;
  for (|@data).sort( -> $a, $b {$a[4]<rps> <=> $b[4]<rps> }) -> Array $x {
    if $slowest.defined {
      $speedup = $x[4]<rps> / $slowest;
    }

    else {
      $speedup = 0e0;
      $slowest = $x[4]<rps>;
    }

    if $markdown {
      $md ~= "|$x[0]|$x[1]|$x[2]|";
      given $x[4] {
        $md ~= ( .<test-text>,
          (.<mean>/1e6).fmt('%.6f'), .<rps>.fmt('%.2f'),
          $speedup == 0.0 ?? '-.--' !! $speedup.fmt('%.2f'), "\n"
        ).join('|');
      }
    }

    if ?$user-sub {
      # Api: Raku Version, Project Version, Sub Project, Speedup,
      #      :total-stime, :count, :mean, :rps, :total-utime,
      #      :total-time, :test-text
      $user-sub( $x[0..2], $speedup, |$x[4]);
    }

    if $tables {
      given $x[4] {
        note [~]
          "\n", .<test-text>, "\n  ",
          "Count:             ", .<count>, "\n  ",
          "Total user time:   ", (.<total-utime>/1e6).fmt('%.5f'), "\n  ",
          "Total system time: ", (.<total-stime>/1e6).fmt('%.5f'), "\n  ",
          "Total of both:     ", (.<total-time>/1e6).fmt('%.5f'), "\n  ",
          "Mean of both:      ", (.<mean>/1e6).fmt('%.5f');

        if $speedup == 0.0 {
          note [~]
            "  Runs/sec:          ", .<rps>.fmt('%.2f'), ' ',
              (0.0).fmt('%.2f'), ' slowest';
        }

        elsif $speedup <= 1.5 {
          note [~]
            "  Runs/sec:          ", .<rps>.fmt('%.2f'), ' ',
              $speedup.fmt('%.2f'),  ' is not much faster'
        }

        else {
          note [~]
            "  Runs/sec:          ", .<rps>.fmt('%.2f'), ' ',
              $speedup.fmt('%.2f'), ' times faster';
        }
      }
    }
  }

  note "\n$md" if $markdown;
}
