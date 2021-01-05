## Release notes

* 2021-01-04 0.4.0
  * Add `meta6-version()` and `type-version()`. `meta6-version()` retrieves the version from the `Meta6.json` file and the project name is prefixed to it. `type-version()` gets the version from a type (Xyz:ver<0.1.0>) and tags the type name (minus project name) upfromt of the found version.
  * Some changes which make use easier. Also `search-compare-tests()` is added to make comparisons between other tests later. E.g. all modules can be compared with each other to show which are more time consuming than others. Or to see if there are improvements after upgrading the Raku compiler.
  * Output can be to simple tables, markdown tables or sent to user functions.

```
my Str $project-version = Gnome::T::Benchmark.meta6-version;
my Str $sub-project = Gnome::T::Benchmark.type-version(Gnome::Gtk3::Assistant);

my Gnome::T::Benchmark $b .= new(
  :default-count(400), :project<gnome-gtk3>, :$project-version,
  :$sub-project, :path<xt/Benchmarking/Data>
);

$b.run-test( 'test purpose text', { ... },
  :prepare( { ... } ),
  :cleanup( { ... } ),
);

$b.run-test( 'test purpose text', { ... },
  :prepare( { ... } ),
  :cleanup( { ... } ),
);
...

$b.load-tests;
$b.modify-tests;
$b.save-tests;

$b.search-compare-tests( :$project-version, :$sub-project, :markdown);
```
showing the next table example in markdown

|Raku Version|Project Version|Sub Project|Test|Mean|Rps|Speedup|
|-|-|-|-|-|-|-|
|Raku-2020.12.32|Gnome::Gtk3-0.34.6|Assistant-0.1.0|Native sub search|0.004502|222.11|-.--|
|Raku-2020.12.32|Gnome::Gtk3-0.34.6|Assistant-0.1.0|Method calls|0.000450|2224.20|10.01|

* 2020-12-20 0.3.0
  * Improved **Gnome::T::Benchmark** `.run-test()` method with `:$prepare`, `:$cleanup` code options.

* 2020-12-19 0.2.0
  * Add benchmarking subroutines from tests of AboutDialog and create module **Gnome::T::Benchmark**.
  * A sample result of markdown table generation of tests

|Project Version|Raku Version|Project|Sub Project|Test|Mean|Rps|Speedup|
|-|-|-|-|-|-|-|-|
|0.34.2.1|2020.10.109|gnome-gtk3|AboutDialog|Method calls|0.00277|360.55|10.46|
|||||Native sub search|0.02902|34.46|0.00|


* 2020-11-08 0.1.0
  * Copy code from gnome-glade3. modified and runs ok. Principle is done for code setup using interface builder glade. Projects build by hand are not yet supported. Module created **Gnome::T::Gui**.
