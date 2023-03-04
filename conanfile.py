import json, os
from conans import ConanFile, tools
from conan.tools.cmake import CMake


class LS50RemoteConan(ConanFile):
    jsonInfo = json.loads(tools.load("info.json"))
    name = jsonInfo["projectName"]
    version = "%u.%u.%u%s" % (jsonInfo["version"]["major"], jsonInfo["version"]["minor"], jsonInfo["version"]["patch"], "-SNAPSHOT" if jsonInfo["version"]["snapshot"] else "")
    license = jsonInfo["license"]
    url = jsonInfo["repository"]
    description = jsonInfo["projectDescription"]
    author = jsonInfo["vendor"]
    homepage = jsonInfo["repository"]
    requires = ("openssl/1.1.1t", "expat/2.4.9", "qt/6.4.2", "QtDeployHelper/1.0.0@tereius/stable")
    settings = {"os": ["Windows", "Linux"], "compiler": None, "build_type": None, "arch": None}
    generators = ["CMakeDeps", "CMakeToolchain", "VirtualRunEnv"]
    exports = "info.json"
    exports_sources = "*"
    options = {"portable": [True, False]}
    default_options = "portable=True", "*:static=False", "qt:shared=True", "qt:gui=True", "qt:qtsvg=True", "qt:qtdeclarative=True" , "qt:qtshadertools=True", "qt:qt5compat=True", "qt:qttools=True", "qt:with_libjpeg=libjpeg", "qt:with_libpng=True", \
                      "qt:disabled_features=clang clangcpp", \
                      "qt:with_vulkan=False", \
                      "qt:with_pcre2=True", \
                      "qt:with_glib=False", \
                      "qt:with_doubleconversion=True", \
                      "qt:with_freetype=True", \
                      "qt:with_fontconfig=True", \
                      "qt:with_icu=False", \
                      "qt:with_harfbuzz=False", \
                      "qt:with_sqlite3=False", \
                      "qt:with_mysql=False", \
                      "qt:with_pq=False", \
                      "qt:with_odbc=False", \
                      "qt:with_zstd=False", \
                      "qt:with_brotli=False", \
                      "qt:with_dbus=False", \
                      "qt:with_libalsa=False", \
                      "qt:with_openal=False", \
                      "qt:with_gstreamer=False", \
                      "qt:with_pulseaudio=False", \
                      "qt:with_gssapi=False", \
                      "qt:with_md4c=False",

    def configure_cmake(self):
        cmake = CMake(self)
        if self.options.portable:
            cmake.configure(variables={"APP_PORTABLE_MODE": True, "CPACK_GENERATOR": "ZIP"})
        else:
            cmake.configure(variables={"APP_PORTABLE_MODE": False, "CPACK_GENERATOR": "NSIS"})
        return cmake

    def build_requirements(self):
        if self.settings.os == "Windows" and not self.options.portable:
            self.build_requires("NSIS/3.03@tereius/stable")

    def build(self):
        cmake = self.configure_cmake()
        cmake.build()

    def package(self):
        cmake = self.configure_cmake()
        if self.settings.os == "Windows":
            cmake.build(target="PACKAGE")
            if self.options.portable:
                self.copy("LS50Remote.zip")
            else:
                self.copy("LS50Remote.exe")
        else:
            cmake.build(target="install")
            self.copy("LS50Remote.AppImage")

    def deploy(self):
        if self.options.portable:
            self.copy("LS50Remote.zip")
        else:
            self.copy("LS50Remote.exe")
