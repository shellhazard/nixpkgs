# Qt packages set.
#
# Attributes in this file are packages requiring Qt and will be made available
# for every Qt version. Qt applications are called from `all-packages.nix` via
# this file.

{
  lib,
  config,
  __splicedPackages,
  makeScopeWithSplicing',
  generateSplicesForMkScope,
  pkgsHostTarget,
}:

let
  pkgs = __splicedPackages;
  # qt5 set should not be pre-spliced to prevent spliced packages being a part of an unspliced set
  # 'pkgsCross.aarch64-multiplatform.pkgsBuildTarget.targetPackages.libsForQt5.qtbase' should not have a `__spliced` but if qt5 is pre-spliced then it will have one.
  # pkgsHostTarget == pkgs
  qt5 = pkgsHostTarget.qt5;
in

makeScopeWithSplicing' {
  otherSplices = generateSplicesForMkScope "libsForQt5";
  f = (
    self:
    let
      libsForQt5 = self;
      callPackage = self.callPackage;

      kdeFrameworks =
        let
          mkFrameworks = import ../development/libraries/kde-frameworks;
          attrs = {
            inherit libsForQt5;
            inherit (pkgs) lib fetchurl;
          };
        in
        (lib.makeOverridable mkFrameworks attrs);

      plasma5 =
        let
          mkPlasma5 = import ../desktops/plasma-5;
          attrs = {
            inherit libsForQt5;
            inherit (pkgs) config lib fetchurl;
            inherit (pkgs) gsettings-desktop-schemas;
          };
        in
        (lib.makeOverridable mkPlasma5 attrs);

      kdeGear =
        let
          mkGear = import ../applications/kde;
          attrs = {
            inherit config libsForQt5;
            inherit (pkgs) lib fetchurl;
          };
        in
        (lib.makeOverridable mkGear attrs);

      plasmaMobileGear =
        let
          mkPlamoGear = import ../applications/plasma-mobile;
          attrs = {
            inherit libsForQt5;
            inherit (pkgs) lib fetchurl;
          };
        in
        (lib.makeOverridable mkPlamoGear attrs);

      mauiPackages =
        let
          mkMaui = import ../applications/maui;
          attrs = {
            inherit libsForQt5;
            inherit (pkgs) lib fetchurl;
          };
        in
        (lib.makeOverridable mkMaui attrs);

      noExtraAttrs =
        set:
        lib.attrsets.removeAttrs set [
          "extend"
          "override"
          "overrideScope"
          "overrideDerivation"
        ];

    in
    (noExtraAttrs (
      kdeFrameworks
      // plasmaMobileGear
      // plasma5
      // plasma5.thirdParty
      // kdeGear
      // mauiPackages
      // qt5
      // {

        inherit
          kdeFrameworks
          plasmaMobileGear
          plasma5
          kdeGear
          mauiPackages
          qt5
          ;

        # Alias for backwards compatibility. Added 2021-05-07.
        kdeApplications = kdeGear;

        ### LIBRARIES

        accounts-qml-module = callPackage ../development/libraries/accounts-qml-module { };

        accounts-qt = callPackage ../development/libraries/accounts-qt { };

        alkimia = callPackage ../development/libraries/alkimia { };

        applet-window-appmenu = callPackage ../development/libraries/applet-window-appmenu { };

        applet-window-buttons = callPackage ../development/libraries/applet-window-buttons { };

        appstream-qt = callPackage ../development/libraries/appstream/qt.nix { };

        dxflib = callPackage ../development/libraries/dxflib { };

        drumstick = callPackage ../development/libraries/drumstick { };

        fcitx5-qt = callPackage ../tools/inputmethods/fcitx5/fcitx5-qt.nix { };

        fcitx5-chinese-addons = callPackage ../tools/inputmethods/fcitx5/fcitx5-chinese-addons.nix { };

        fcitx5-configtool = callPackage ../tools/inputmethods/fcitx5/fcitx5-configtool.nix { };

        fcitx5-skk-qt = callPackage ../tools/inputmethods/fcitx5/fcitx5-skk.nix { enableQt = true; };

        fcitx5-unikey = callPackage ../tools/inputmethods/fcitx5/fcitx5-unikey.nix { };

        fcitx5-with-addons = callPackage ../tools/inputmethods/fcitx5/with-addons.nix { };

        futuresql = callPackage ../development/libraries/futuresql { };

        qgpgme = callPackage ../development/libraries/gpgme { };

        grantlee = callPackage ../development/libraries/grantlee/5 { };

        qtcurve = callPackage ../data/themes/qtcurve { };

        herqq = callPackage ../development/libraries/herqq { };

        kdb = callPackage ../development/libraries/kdb { };

        kde2-decoration = callPackage ../data/themes/kde2 { };

        kcolorpicker = callPackage ../development/libraries/kcolorpicker { };

        kdiagram = callPackage ../development/libraries/kdiagram { };

        kdsoap = callPackage ../development/libraries/kdsoap { };

        kf5gpgmepp = callPackage ../development/libraries/kf5gpgmepp { };

        kirigami-addons = libsForQt5.callPackage ../development/libraries/kirigami-addons { };

        kimageannotator = callPackage ../development/libraries/kimageannotator { };

        kproperty = callPackage ../development/libraries/kproperty { };

        kpeoplevcard = callPackage ../development/libraries/kpeoplevcard { };

        kreport = callPackage ../development/libraries/kreport { };

        kquickimageedit = callPackage ../development/libraries/kquickimageedit/0.3.0.nix { };

        kuserfeedback = callPackage ../development/libraries/kuserfeedback { };

        kweathercore = libsForQt5.callPackage ../development/libraries/kweathercore { };

        ldutils = callPackage ../development/libraries/ldutils { };

        libcommuni = callPackage ../development/libraries/libcommuni { };

        libdbusmenu = callPackage ../development/libraries/libdbusmenu-qt/qt-5.5.nix { };

        libiodata = callPackage ../development/libraries/libiodata { };

        liblastfm = callPackage ../development/libraries/liblastfm { };

        libopenshot = callPackage ../development/libraries/libopenshot { };

        packagekit-qt = callPackage ../tools/package-management/packagekit/qt.nix { };

        libopenshot-audio = callPackage ../development/libraries/libopenshot-audio { };

        libqglviewer = callPackage ../development/libraries/libqglviewer { };

        libqofono = callPackage ../development/libraries/libqofono { };

        libqtpas = callPackage ../development/compilers/fpc/libqtpas.nix { };

        libqaccessibilityclient = callPackage ../development/libraries/libqaccessibilityclient { };

        mapbox-gl-native = libsForQt5.callPackage ../development/libraries/mapbox-gl-native { };

        mapbox-gl-qml = libsForQt5.callPackage ../development/libraries/mapbox-gl-qml { };

        maplibre-gl-native = callPackage ../development/libraries/maplibre-gl-native { };

        maplibre-native-qt = callPackage ../development/libraries/maplibre-native-qt { };

        maui-core = libsForQt5.callPackage ../development/libraries/maui-core { };

        mlt = pkgs.mlt.override {
          qt = qt5;
        };

        phonon = callPackage ../development/libraries/phonon { };

        phonon-backend-gstreamer = callPackage ../development/libraries/phonon/backends/gstreamer.nix { };

        phonon-backend-vlc = callPackage ../development/libraries/phonon/backends/vlc.nix { };

        plasma-wayland-protocols = callPackage ../development/libraries/plasma-wayland-protocols { };

        polkit-qt = callPackage ../development/libraries/polkit-qt-1 { };

        poppler = callPackage ../development/libraries/poppler {
          lcms = pkgs.lcms2;
          qt5Support = true;
          suffix = "qt5";
        };

        pulseaudio-qt = callPackage ../development/libraries/pulseaudio-qt { };

        qca = callPackage ../development/libraries/qca {
          inherit (libsForQt5) qtbase;
        };
        qca-qt5 = self.qca;

        qcoro = callPackage ../development/libraries/qcoro { };

        qcsxcad = callPackage ../development/libraries/science/electronics/qcsxcad { };

        qcustomplot = callPackage ../development/libraries/qcustomplot { };

        qjson = callPackage ../development/libraries/qjson { };

        qmltermwidget = callPackage ../development/libraries/qmltermwidget { };

        qmlbox2d = callPackage ../development/libraries/qmlbox2d { };

        qoauth = callPackage ../development/libraries/qoauth { };

        qt5ct = callPackage ../tools/misc/qt5ct { };

        qtdbusextended = callPackage ../development/libraries/qtdbusextended { };

        qtfeedback = callPackage ../development/libraries/qtfeedback { };

        qtforkawesome = callPackage ../development/libraries/qtforkawesome { };

        qtutilities = callPackage ../development/libraries/qtutilities { };

        qtinstaller = callPackage ../development/libraries/qtinstaller { };

        qtkeychain = callPackage ../development/libraries/qtkeychain { };

        qtmpris = callPackage ../development/libraries/qtmpris { };

        qtpbfimageplugin = callPackage ../development/libraries/qtpbfimageplugin { };

        qtstyleplugins = callPackage ../development/libraries/qtstyleplugins { };

        qtstyleplugin-kvantum = callPackage ../development/libraries/qtstyleplugin-kvantum {
          qt6Kvantum = pkgs.qt6Packages.qtstyleplugin-kvantum;
        };

        quazip = callPackage ../development/libraries/quazip { };

        quickflux = callPackage ../development/libraries/quickflux { };

        qscintilla = callPackage ../development/libraries/qscintilla { };

        qwt = callPackage ../development/libraries/qwt/default.nix { };

        qwt6_1 = callPackage ../development/libraries/qwt/6_1.nix { };

        qxlsx = callPackage ../development/libraries/qxlsx { };

        qzxing = callPackage ../development/libraries/qzxing { };

        rlottie-qml = callPackage ../development/libraries/rlottie-qml { };

        sailfish-access-control-plugin =
          callPackage ../development/libraries/sailfish-access-control-plugin
            { };

        sierra-breeze-enhanced = callPackage ../data/themes/kwin-decorations/sierra-breeze-enhanced {
          useQt5 = true;
        };

        soqt = callPackage ../development/libraries/soqt { };

        telepathy = callPackage ../development/libraries/telepathy/qt { };

        qtwebkit-plugins = callPackage ../development/libraries/qtwebkit-plugins { };

        # Not a library, but we do want it to be built for every qt version there
        # is, to allow users to choose the right build if needed.
        sddm = callPackage ../applications/display-managers/sddm { };

        signond = callPackage ../development/libraries/signond { };

        soundkonverter = callPackage ../applications/audio/soundkonverter { };

        timed = callPackage ../applications/system/timed { };

        xp-pen-deco-01-v2-driver = callPackage ../os-specific/linux/xp-pen-drivers/deco-01-v2 { };

        xp-pen-g430-driver = callPackage ../os-specific/linux/xp-pen-drivers/g430 { };

        xwaylandvideobridge = callPackage ../tools/wayland/xwaylandvideobridge { };
      }
    ))
  );
}
