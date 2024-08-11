# QtAppBase

[![Conan Remote Recipe](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fapi.github.com%2Frepos%2FPrivatehive%2FQtAppBase%2Fproperties%2Fvalues&query=%24%5B%3F(%40.property_name%20%3D%3D%20'conan-package')%5D.value&style=flat&logo=conan&label=conan&color=%232980b9)](https://conan.privatehive.de/ui/repos/tree/General/public-conan/de.privatehive) 

#### Bundles common functionalities for all Qt based Apps

---

| os        | arch     | CI Status                                                                                                                                                                                                                                                   |
| --------- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Linux`   | `x86_64` | [![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/Privatehive/QtAppBase/main.yml?branch=master&style=flat&logo=github&label=create+package)](https://github.com/Privatehive/QtAppBase/actions?query=branch%3Amaster) |
| `Windows` | `x86_64` | [![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/Privatehive/QtAppBase/main.yml?branch=master&style=flat&logo=github&label=create+package)](https://github.com/Privatehive/QtAppBase/actions?query=branch%3Amaster) |
| `Android` | `armv8`  | [![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/Privatehive/QtAppBase/main.yml?branch=master&style=flat&logo=github&label=create+package)](https://github.com/Privatehive/QtAppBase/actions?query=branch%3Amaster) |

### Features

* `LogMessageHandler` logger with log rotation functionality
* `QtApplicationBase` a wrapper for native Qt QCoreApplication, QGuiApplication classes used for bootstrapping
* [`qml=True`] `QmlApplicationEngine` with hot reloading support
* `SecretsManager`
* CMake based deployment for Android, Linux, Windows
    * Linux: Installer, AppImage
    * Window: Installer, zip package
    * Android: APK, AAB

### How to run on Raspberry Pi (EGLFS)

Flash the Raspberry Pi OS Lite image

* Enable the GL (Full KMS) driver in raspi-config (also make sure at least 64 MB GPU memory is selected)
* Install: libegl1, libgles2, libxkbcommon0, libinput10
* Run the AppImage

### How to compile AppImage runtime for Armv6

The [AppImageKit](https://github.com/AppImage/AppImageKit) release only contains the AppImage binaries for x86_64, i686,
aarch64, armhf (
armv7). Binaries for armv6 are missing (necessary for some Raspberry PIs).

To compile the Armv6 binaries do the following:

* Install Raspberry Pi OS Lite (Legacy)
* Update the system
  `sudo apt-get update && sudo apt-get upgrade`
* Install the following packages
  `sudo apt-get install git cmake automake zsync libtool desktop-file-utils libglib2.0-dev libcairo2-dev libfuse-dev libssl-dev libgpgme-dev libgcrypt-dev`
* Clone the [AppImageKit](https://github.com/AppImage/AppImageKit) repo:
  `git clone --recurse-submodules https://github.com/AppImage/AppImageKit.git`
* Apply the following patch

```patch
diff --git a/src/CMakeLists.txt b/src/CMakeLists.txt
index f2247b4..f9f2df5 100644
--- a/src/CMakeLists.txt
+++ b/src/CMakeLists.txt
@@ -31,8 +31,8 @@ target_include_directories(appimagetool
 # required for appimagetool's signing
 # we're using CMake's functionality directly, since we want to link those statically
 find_package(PkgConfig)
-pkg_check_modules(libgpgme REQUIRED gpgme IMPORTED_TARGET)
-pkg_check_modules(libgcrypt REQUIRED libgcrypt IMPORTED_TARGET)
+find_library(LIB_libgpgme NAMES gpgme)
+find_library(LIB_libgcrypt NAMES gcrypt)
 
 # trick: list libraries on which imported static ones depend on in the PUBLIC section
 # CMake then adds them after the PRIVATE ones in the linker command
@@ -44,8 +44,8 @@ target_link_libraries(appimagetool
     libglib
     libgio
     libzlib
-    PkgConfig::libgcrypt
-    PkgConfig::libgpgme
+    ${LIB_libgcrypt}
+    ${LIB_libgpgme}
     xz
 )
```

* Run `./ci/build-binaries-and-appimage.sh`

You should now see the follwing binaries `appimagetool-.AppImage`, `AppRun`, `runtime` (the arch suffix `armv6` is
missing).
