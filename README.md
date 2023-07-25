# QtAppBase

This Repo provides the basics for every Qt6 based App:

* A QmlApplicationEngine with hot reloading support
* A LogMessageHandler with log rotation
* Deployment helper for Android, RaspberryPi

### How to compile AppImage runtime for Armv6

The [AppImageKit](https://github.com/AppImage/AppImageKit) only releases the AppImage binaries for x86_64, i686, aarch64, armhf (armv7).
Binaries for armv6 are missing (necessary for some Raspberry PIs).

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

You should now see the follwing binaries `appimagetool-.AppImage`, `AppRun`, `runtime` (the arch suffix `armv6` is missing).
