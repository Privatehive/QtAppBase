cmake_minimum_required(VERSION 3.21.1)
project(QtAppBase)

# Set a default search path for CMake modules
set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/CMake" "${CMAKE_MODULE_PATH}")
include(QtAppBase)

qt_app_project_setup(PROJECT_SETUP_INFO)
project(${PROJECT_SETUP_INFO})

qt_app_setup()

add_subdirectory(src)

install(
        FILES
        "${CMAKE_SOURCE_DIR}/CMake/Findsigntool.cmake"
        "${CMAKE_SOURCE_DIR}/CMake/JSONParser.cmake"
        "${CMAKE_SOURCE_DIR}/CMake/QtAppBase.cmake"
        "${CMAKE_SOURCE_DIR}/CMake/QtAppBaseCommon.cmake"
        "${CMAKE_SOURCE_DIR}/CMake/MaterialIcons.cmake"
        "${CMAKE_SOURCE_DIR}/CMake/AppImage.cmake"
        "${CMAKE_SOURCE_DIR}/CMake/AppImage.desktop.in"
        "${CMAKE_SOURCE_DIR}/CMake/QtIF.cmake"
        "${CMAKE_SOURCE_DIR}/CMake/QtIF.config.in"
        "${CMAKE_SOURCE_DIR}/CMake/QtIF.package.in"
        "${CMAKE_SOURCE_DIR}/CMake/QtIF.install.qs.in"
        "${CMAKE_SOURCE_DIR}/CMake/QtIF.control.qs"
        "${CMAKE_SOURCE_DIR}/CMake/GetDependencies.cmake"
        "${CMAKE_SOURCE_DIR}/CMake/AndroidDeploy.cmake"
        "${CMAKE_SOURCE_DIR}/CMake/AndroidManifest.xml.in"
        "${CMAKE_SOURCE_DIR}/CMake/mimeMap.xml.in"
        "${CMAKE_SOURCE_DIR}/CMake/PKGBUILD.cmake"
        "${CMAKE_SOURCE_DIR}/CMake/PKGBUILD.in"
        "${CMAKE_SOURCE_DIR}/CMake/win32resource.rc.in"
        DESTINATION
        "${CMAKE_INSTALL_LIBDIR}/cmake"
)
