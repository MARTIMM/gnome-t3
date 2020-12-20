use v6;

use Gnome::T::Benchmark;
use Gnome::Gtk3::AboutDialog;

my Gnome::Gtk3::AboutDialog $*about-dialog;
my Gnome::T::Benchmark $b .= new(
  :default-count(500), :project<gnome-gtk3>, :project-version<0.34.2.1>,
  :sub-project<AboutDialog>, :path<xt/Benchmark/Data>
);
$b.run-test( 'Method calls', {
    given $*about-dialog {
      .set-program-name('AboutDialog.t');
      my Str $s = .get-program-name;

      .set-version('0.14.2.1');
      $s = .get-version;

      .set-copyright('m.timmerman a.k.a MARTIMM');
      $s = .get-copyright;

      .set-comments('Very good language binding');
      $s = .get-comments;

      .set-license('Artistic License 2.0');
      $s = .get-license;

      .set-license-type(GTK_LICENSE_MIT_X11);
      my GtkLicense $t = .get-license-type;

      .set-wrap-license(GTK_LICENSE_MIT_X11);
      my Bool $b = .get-wrap-license;

      .set-website('https://example.com/my-favourite-items.html');
      $s = .get-website;

      .set-website-label('favourite');
      $s = .get-website-label;

      .set-authors( 'mt++1', 'pietje puk1');
      my Array $arr = .get-authors;

      .set-documenters( 'mt++2', 'pietje puk2');
      $arr = .get-documenters;

      .set-artists( 'mt++3', 'pietje puk3');
      $arr = .get-artists;

      .set-translator-credits('He, who has invented Raku, thanks a lot');
      $s = .get-translator-credits;

      .set-logo-icon-name('folder-blue');
      $s = .get-logo-icon-name;

      .add-credit-section( 'piano players', 'lou de haringboer', 'kniertje');
    }
  }, :prepare( {
      $*about-dialog .= new;
    }
  ), :cleanup( {
      $*about-dialog.destroy;
    }
  )
);

$b.run-test( 'Native sub search', {
    given $*about-dialog {
      .gtk-about-dialog-set-program-name('AboutDialog.t');
      my Str $s = .gtk-about-dialog-get-program-name;

      .gtk-about-dialog-set-version('0.14.2.1');
      $s = .gtk-about-dialog-get-version;

      .gtk-about-dialog-set-copyright('m.timmerman a.k.a MARTIMM');
      $s = .gtk-about-dialog-get-copyright;

      .gtk-about-dialog-set-comments('Very good language binding');
      $s = .gtk-about-dialog-get-comments;

      .gtk-about-dialog-set-license('Artistic License 2.0');
      $s = .gtk-about-dialog-get-license;

      .gtk-about-dialog-set-license-type(GTK_LICENSE_MIT_X11);
      my GtkLicense $t = .gtk-about-dialog-get-license-type;

      .gtk-about-dialog-set-wrap-license(GTK_LICENSE_MIT_X11);
      my Int $b = .gtk-about-dialog-get-wrap-license;

      .gtk-about-dialog-set-website(
        'https://example.com/my-favourite-items.html'
      );
      $s = .gtk-about-dialog-get-website;

      .gtk-about-dialog-set-website-label('favourite');
      $s = .gtk-about-dialog-get-website-label;

      .gtk-about-dialog-set-authors( 'mt++1', 'pietje puk1');
      my Array $arr = .gtk-about-dialog-get-authors;

      .gtk-about-dialog-set-documenters( 'mt++2', 'pietje puk2');
      $arr = .gtk-about-dialog-get-documenters;

      .gtk-about-dialog-set-artists( 'mt++3', 'pietje puk3');
      $arr = .gtk-about-dialog-get-artists;

      .gtk-about-dialog-set-translator-credits(
        'He, who has invented Raku, thanks a lot'
      );
      $s = .gtk-about-dialog-get-translator-credits;

      .gtk-about-dialog-set-logo-icon-name('folder-blue');
      $s = .gtk-about-dialog-get-logo-icon-name;

      .gtk-about-dialog-add-credit-section(
        'piano players', 'lou de haringboer', 'kniertje'
      );
    }
  }, :prepare( {
      $*about-dialog .= new;
    }
  ), :cleanup( {
      $*about-dialog.destroy;
    }
  )
);

$b.compare-tests;

#$b.show-test('Native sub search');
#$b.show-test('Method calls');
$b.save-tests;

$b.md-test-table( '0.34.2.1', '2020.10.109', 'AboutDialog', 0, 1);
