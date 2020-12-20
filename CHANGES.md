## Release notes

* 2020-12-19 0.0.2
  * Add benchmarking subroutines from tests of AboutDialog and create module **Gnome::T::Benchmark**.
  * A sample result of markdown table generation of tests

|Project Version|Raku Version|Project|Sub Project|Test|Mean|Rps|Speedup|
|-|-|-|-|-|-|-|-|
|0.34.2.1|2020.10.109|gnome-gtk3|AboutDialog|Method calls|0.00277|360.55|10.46|
|||||Native sub search|0.02902|34.46|0.00|


* 2020-11-08 0.0.1
  * Copy code from gnome-glade3. modified and runs ok. Principle is done for code setup using interface builder glade. Projects build by hand are not yet supported. Module created **Gnome::T::Gui**.
