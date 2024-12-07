cmake_minimum_required(VERSION 3.21.1)
set(current_dir ${CMAKE_CURRENT_LIST_DIR})

macro(register_target_properties)
    define_property(TARGET PROPERTY APPBASE_QTIF_SOURCE_DIR BRIEF_DOCS "Qt Installer related files" FULL_DOCS "Qt Installer related files")
    define_property(TARGET PROPERTY APPBASE_ASSOCIATED_EXTENSIONS BRIEF_DOCS "Qt Installer related files" FULL_DOCS "Qt Installer related files")
    define_property(TARGET PROPERTY APPBASE_ICON BRIEF_DOCS "Qt Installer related files" FULL_DOCS "Qt Installer related files")
endmacro()

macro(parse_info INFO_FILE)

    include(JSONParser)
    file(READ "${INFO_FILE}" jsonInfo)
    sbeParseJson(info jsonInfo)

    string(TOLOWER "${info.projectName}" info.projectNameLowerCase)
    set(info.package "${info.domain}.${info.projectNameLowerCase}")
    string(REPLACE "." "/" info.packagejni "${info.package}")
    set(info.copyrightString "Copyright (c) ${info.copyrightYear} ${info.vendor}")

    if (${info.version.snapshot})
        set(info.versionString "${info.version.major}.${info.version.minor}.${info.version.patch}-snapshot")
    else ()
        set(info.versionString "${info.version.major}.${info.version.minor}.${info.version.patch}")
    endif ()

    set(info.topics_list "")
    foreach (var ${info.topics})
        list(APPEND info.topics_list "${info.topics_${var}}")
    endforeach ()

    set(info.categories_list "")
    foreach (var ${info.categories})
        list(APPEND info.categories_list "${info.categories_${var}}")
    endforeach ()

    list(APPEND info info.package info.packagejni info.versionString info.projectNameLowerCase)
endmacro()

macro(qt_app_project_setup PROJECT_SETUP_INFO_VAR)

    if (NOT EXISTS "${PROJECT_SOURCE_DIR}/LICENSE")
        message(NOTICE "QtAppBase: Missing LICENSE file in project folder. Creating a placeholder.")
        file(WRITE "${PROJECT_SOURCE_DIR}/LICENSE" "TODO")
    endif ()

    if (NOT EXISTS "${PROJECT_SOURCE_DIR}/info.json")
        message(NOTICE "QtAppBase: Missing info.json file in project folder. Creating a generic one.")
        string(TIMESTAMP CURRENT_YEAR %Y)
        string(TIMESTAMP TIMESTAMP_ID %s UTC)
        file(WRITE "${PROJECT_SOURCE_DIR}/info.json" "{
  \"version\": {
    \"major\": 1,
    \"minor\": 0,
    \"patch\": 0,
    \"snapshot\": true
  },
  \"projectName\": \"GenericProject\",
  \"projectDescription\": \"-\",
  \"projectId\": \"${TIMESTAMP_ID}\",
  \"vendor\": \"-\",
  \"contact\": \"-\",
  \"domain\": \"-\",
  \"copyrightYear\": \"${CURRENT_YEAR}\",
  \"repository\": \"-\",
  \"topics\": [],
  \"categories\": [],
  \"homepage\": \"-\",
  \"license\": \"-\"
}")
    endif ()

    # Parse the info.json
    parse_info("${PROJECT_SOURCE_DIR}/info.json")

    set(${PROJECT_SETUP_INFO_VAR} "${info.projectName}" "VERSION" "${info.version.major}.${info.version.minor}.${info.version.patch}" "DESCRIPTION" "${info.projectDescription}" "HOMEPAGE_URL" "${info.repository}" "LANGUAGES" "C" "CXX")
endmacro()

macro(qt_app_setup)

    set(CMAKE_CXX_STANDARD 17)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)

    # Configure a header file to pass some of the CMake settings to the source code.
    include_directories("${PROJECT_BINARY_DIR}/.qtappbase")
    file(WRITE "${PROJECT_BINARY_DIR}/.qtappbase/info.h" "#pragma once\n")
    foreach (var ${info})
        string(TOUPPER "${var}" UPPER_VAR)
        string(REPLACE "." "_" UPPER_VAR "${UPPER_VAR}")
        list(LENGTH ${var} LIST_LEN)
        if (LIST_LEN EQUAL 1)
            if (${${var}} MATCHES "^[0-9]+$")
                file(APPEND "${PROJECT_BINARY_DIR}/.qtappbase/info.h" "#define ${UPPER_VAR} ${${var}}\n")
            else ()
                file(APPEND "${PROJECT_BINARY_DIR}/.qtappbase/info.h" "#define ${UPPER_VAR} \"${${var}}\"\n")
            endif ()
        endif ()
    endforeach ()

    if (ANDROID)
        set(QT_ENABLE_VERBOSE_DEPLOYMENT OFF) # If ON leads to sign error
        #set(QT_NO_GLOBAL_APK_TARGET_PART_OF_ALL ON)
        if (CMAKE_BUILD_TYPE STREQUAL "Release" OR CMAKE_BUILD_TYPE STREQUAL "MinSizeRel")
            message(STATUS "QtAppBase: Configuring release/signed APK, AAB")
            if (DEFINED ENV{QT_ANDROID_KEYSTORE_PATH})
                set(QT_ANDROID_DEPLOY_RELEASE ON)
                set(QT_ANDROID_SIGN_APK ON)
                set(QT_ANDROID_SIGN_AAB ON)
            else ()
                message(WARNING "QtAppBase: Missing ENV QT_ANDROID_KEYSTORE_PATH pointing to a keystore. APK, AAB will be signed with debug key")
                set(QT_ANDROID_DEPLOY_RELEASE OFF)
                set(QT_ANDROID_SIGN_APK OFF)
                set(QT_ANDROID_SIGN_AAB OFF)
            endif ()
        else ()
            message(STATUS "QtAppBase: Configuring debug/debug-signed APK, AAB")
            set(QT_ANDROID_DEPLOY_RELEASE OFF)
            set(QT_ANDROID_SIGN_APK OFF)
            set(QT_ANDROID_SIGN_AAB OFF)
        endif ()
        #message(STATUS "Run target 'apk' to build APK")
        message(STATUS "QtAppBase: Run target 'aab' to build AAB")
    endif ()

    find_package(Qt6 REQUIRED REQUIRED Core)
    find_package(Qt6 OPTIONAL_COMPONENTS Qml)

    if (Qt6Qml_DIR)
        if (QT_KNOWN_POLICY_QTP0001)
            qt_policy(SET QTP0001 NEW)
        endif ()
        if (QT_KNOWN_POLICY_QTP0004)
            qt_policy(SET QTP0004 NEW)
        endif ()
    endif ()
    if (QT_KNOWN_POLICY_QTP0002)
        qt_policy(SET QTP0002 NEW)
    endif ()
    if (QT_KNOWN_POLICY_QTP0003)
        qt_policy(SET QTP0003 NEW)
    endif ()

    qt_standard_project_setup()

    file(COPY "${PROJECT_SOURCE_DIR}/LICENSE" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}")
    install(FILES "${PROJECT_SOURCE_DIR}/LICENSE" DESTINATION "${CMAKE_INSTALL_PREFIX}")

    register_target_properties()

    cmake_language(DEFER CALL
            set (CPACK_PACKAGE_NAME "${info.projectName}")
            set (CPACK_PACKAGE_DESCRIPTION_SUMMARY "${info.projectDescription}")
            set (CPACK_PACKAGE_VENDOR "${info.vendor}")
            set (CPACK_PACKAGE_CONTACT "${info.contact}")
            set (CPACK_PACKAGE_HOMEPAGE_URL "${info.repository}")
            set (CPACK_RESOURCE_FILE_LICENSE "${PROJECT_SOURCE_DIR}/LICENSE")
            set (CPACK_PACKAGE_VERSION_MAJOR ${info.version.major})
            set (CPACK_PACKAGE_VERSION_MINOR ${info.version.minor})
            set (CPACK_PACKAGE_VERSION_PATCH ${info.version.patch})
            set (CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)
            set (CPACK_PACKAGE_INSTALL_DIRECTORY "${PROJECT_NAME}")
            set (CPACK_PACKAGE_FILE_NAME "${PROJECT_NAME}")
            set (CPACK_PACKAGE_EXECUTABLES "${PROJECT_NAME};${PROJECT_NAME}")
            set (CPACK_STRIP_FILES ON)
            set (CPACK_PACKAGE_CHECKSUM SHA256)

            set (CPACK_NSIS_EXTRA_UNINSTALL_COMMANDS "ExecWait '\\\"$INSTDIR\\\\bin\\\\${PROJECT_NAME}${CMAKE_EXECUTABLE_SUFFIX}\\\" -u'")
    )
endmacro()

function(target_mark_public_header TARGET)

    get_target_property(CURRENT_PUBLIC_HEADER ${TARGET} PUBLIC_HEADER)
    if (CURRENT_PUBLIC_HEADER)
        set_target_properties(${TARGET} PROPERTIES PUBLIC_HEADER "${ARGN};${CURRENT_PUBLIC_HEADER}")
    else ()
        set_target_properties(${TARGET} PROPERTIES PUBLIC_HEADER "${ARGN}")
    endif ()
endfunction()

function(add_dependency TARGET)

    set_property(
            TARGET ${TARGET}
            APPEND PROPERTY
            INSTALL_DEPENDS "${ARGN}"
    )
endfunction()

function(_combine_with_resource_targets TARGET OUT)
    set(install_targest ${TARGET})
    foreach (i RANGE 1 100)
        set(resource_target_name "${TARGET}_resources_${i}")
        if (TARGET ${resource_target_name})
            message(STATUS "QtAppBase:  found resource target ${resource_target_name}")
            list(APPEND install_targest "${resource_target_name}")
        endif ()
    endforeach ()
    set(${OUT} ${install_targest} PARENT_SCOPE)
endfunction()

function(_combine_with_init_targets TARGET OUT)
    set(install_targest ${TARGET})
    set(init_target_name "${TARGET}_init")
    if (TARGET ${init_target_name})
        message(STATUS "QtAppBase:  found init target ${init_target_name}")
        list(APPEND install_targest "${init_target_name}")
    endif ()
    set(${OUT} ${install_targest} PARENT_SCOPE)
endfunction()

function(install_qt_library TARGET)

    message(STATUS "QtAppBase: Install Qt library ${TARGET}")
    set(staging_prefix ".")
    _combine_with_resource_targets(${TARGET} INSTALL_TARGETS)
    install(TARGETS ${INSTALL_TARGETS}
            EXPORT ${TARGET}-Targets
            ARCHIVE DESTINATION "${staging_prefix}/${CMAKE_INSTALL_LIBDIR}"
            LIBRARY DESTINATION "${staging_prefix}/${CMAKE_INSTALL_LIBDIR}"
            RUNTIME DESTINATION "${staging_prefix}/${CMAKE_INSTALL_BINDIR}"
            OBJECTS DESTINATION "${staging_prefix}/${CMAKE_INSTALL_LIBDIR}"
            PUBLIC_HEADER DESTINATION "${staging_prefix}/${CMAKE_INSTALL_INCLUDEDIR}"
    )

    install(EXPORT ${TARGET}-Targets
            DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/${TARGET}"
    )

    file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}Config.cmake.in" "include(CMakeFindDependencyMacro)")
    file(APPEND "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}Config.cmake.in" "\nfind_dependency(Qt6 COMPONENTS Core)")

    get_target_property(INSTALL_DEPENDS ${TARGET} INSTALL_DEPENDS)
    if (INSTALL_DEPENDS)
        foreach (DEPENDS IN LISTS INSTALL_DEPENDS)
            file(APPEND "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}Config.cmake.in" "\nfind_dependency(${DEPENDS})")
        endforeach ()
    endif ()

    file(APPEND "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}Config.cmake.in" "\ninclude(\"\${CMAKE_CURRENT_LIST_DIR}/${TARGET}-Targets.cmake\")")

    configure_file(${CMAKE_CURRENT_BINARY_DIR}/${TARGET}Config.cmake.in ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}Config.cmake COPYONLY)

    install(
            FILES ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}Config.cmake
            DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/${TARGET}"
    )
endfunction()

# https://doc.qt.io/qt-6/qt-query-qml-module.html#example
# Qt can't install qml modules yet. We have to provide a solution.
function(install_qml_module TARGET)

    message(STATUS "QtAppBase: Install QML module ${TARGET}")
    qt_query_qml_module(${TARGET}
            URI module_uri
            VERSION module_version
            PLUGIN_TARGET module_plugin_target
            TARGET_PATH module_target_path
            QMLDIR module_qmldir
            TYPEINFO module_typeinfo
            QML_FILES module_qml_files
            QML_FILES_DEPLOY_PATHS qml_files_deploy_paths
            RESOURCES module_resources
            RESOURCES_DEPLOY_PATHS resources_deploy_paths
    )

    set(include_targets "include(\"\${CMAKE_CURRENT_LIST_DIR}/${TARGET}-Targets.cmake\")")

    # Install the QML module backing library
    set(staging_prefix ".")
    _combine_with_resource_targets(${TARGET} INSTALL_TARGETS)
    install(TARGETS ${INSTALL_TARGETS}
            EXPORT ${TARGET}-Targets
            ARCHIVE DESTINATION "${staging_prefix}/${CMAKE_INSTALL_LIBDIR}"
            LIBRARY DESTINATION "${staging_prefix}/${CMAKE_INSTALL_LIBDIR}"
            RUNTIME DESTINATION "${staging_prefix}/${CMAKE_INSTALL_BINDIR}"
            OBJECTS DESTINATION "${staging_prefix}/${CMAKE_INSTALL_LIBDIR}"
            PUBLIC_HEADER DESTINATION "${staging_prefix}/${CMAKE_INSTALL_INCLUDEDIR}"
    )
    set(module_dir "${staging_prefix}/qml/${module_target_path}")

    install(EXPORT ${TARGET}-Targets
            DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/${TARGET}"
    )

    if (TARGET "${module_plugin_target}")
        # Install the QML module runtime loadable plugin
        _combine_with_init_targets(${module_plugin_target} INSTALL_TARGETS)
        install(TARGETS ${INSTALL_TARGETS}
                EXPORT ${module_plugin_target}-Targets
                ARCHIVE DESTINATION "${module_dir}"
                LIBRARY DESTINATION "${module_dir}"
                RUNTIME DESTINATION "${module_dir}"
                OBJECTS DESTINATION "${module_dir}"
        )
        install(EXPORT ${module_plugin_target}-Targets
                DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/${TARGET}"
        )
        set(include_targets "${include_targets}\ninclude(\"\${CMAKE_CURRENT_LIST_DIR}/${module_plugin_target}-Targets.cmake\")")
    endif ()

    file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}Config.cmake.in" "include (CMakeFindDependencyMacro)
    # TODO find_package not complete
    find_package(Qt6 REQUIRED COMPONENTS Core Qml Gui Quick)
    ${include_targets}

    # Workaround to provide qmlimportscanner with a -importPath arg called during qt_deploy_qml_imports
    set(qml_import_paths \"\")
    get_target_property(qml_import_path ${TARGET} QT_QML_IMPORT_PATH)
    if(qml_import_path)
    list(APPEND qml_import_paths \${qml_import_path})
    endif()
    list(APPEND qml_import_paths \"\${CMAKE_CURRENT_LIST_DIR}/../../../qml\")
    set_target_properties(${TARGET} PROPERTIES QT_QML_IMPORT_PATH \${qml_import_paths})
    ")

    configure_file(${CMAKE_CURRENT_BINARY_DIR}/${TARGET}Config.cmake.in ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}Config.cmake COPYONLY)

    install(
            FILES ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}Config.cmake
            DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/${TARGET}"
    )

    # Install the QML module meta information.
    install(FILES "${module_qmldir}" DESTINATION "${module_dir}")
    install(FILES "${module_typeinfo}" DESTINATION "${module_dir}")

    # Install QML files, possibly renamed.
    list(LENGTH module_qml_files num_files)
    math(EXPR last_index "${num_files} - 1")
    if (${last_index} GREATER_EQUAL 0)
        foreach (i RANGE 0 ${last_index})
            list(GET module_qml_files ${i} src_file)
            list(GET qml_files_deploy_paths ${i} deploy_path)
            get_filename_component(dst_name "${deploy_path}" NAME)
            get_filename_component(dest_dir "${deploy_path}" DIRECTORY)
            install(FILES "${src_file}" DESTINATION "${module_dir}/${dest_dir}" RENAME "${dst_name}")
        endforeach ()
    endif ()

    # Install resources, possibly renamed.
    list(LENGTH module_resources num_files)
    math(EXPR last_index "${num_files} - 1")
    if (${last_index} GREATER_EQUAL 0)
        foreach (i RANGE 0 ${last_index})
            list(GET module_resources ${i} src_file)
            list(GET resources_deploy_paths ${i} deploy_path)
            get_filename_component(dst_name "${deploy_path}" NAME)
            get_filename_component(dest_dir "${deploy_path}" DIRECTORY)
            install(FILES "${src_file}" DESTINATION "${module_dir}/${dest_dir}" RENAME "${dst_name}")
        endforeach ()
    endif ()
endfunction()

# register_file_extension(target EXTENSION extension MIME_TYPE mime [COMMENT comment])
function(register_file_extension TARGET)

    set(options)
    set(oneValueArgs EXTENSION MIME_TYPE COMMENT)
    set(multiValueArgs)
    cmake_parse_arguments(OPTIONS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    set(file_extensions "")
    # Get custom import paths provided during qt_add_qml_module call.
    get_target_property(_existing ${TARGET} APPBASE_ASSOCIATED_EXTENSIONS)
    if (_existing)
        list(APPEND file_extensions ${_existing})
    endif ()

    list(APPEND file_extensions "${OPTIONS_EXTENSION},${OPTIONS_MIME_TYPE},${OPTIONS_COMMENT}")
    set_target_properties(${TARGET} PROPERTIES APPBASE_ASSOCIATED_EXTENSIONS "${file_extensions}")
endfunction()

# register_icon(target [SCALABLE svg_image] [ICO ico_image] [ICNS ICNS_image [1024x1024 png_image] [512x512 png_image] [256x256 png_image] [128x128 png_image] [64x64 png_image] [48x48 png_image] [32x32 png_image] [16x16 png_image])
# supported image types:
# Linux: PNG, XPM, SVG
# Windows: ICO
# Macos: ICNS (use https://github.com/alptugan/icns-creator)
function(register_icon TARGET)

    set(options)
    set(oneValueArgs SCALABLE ICO ICNS 1024x1024 512x512 256x256 128x128 64x64 48x48 32x32 16x16)
    set(multiValueArgs)
    cmake_parse_arguments(OPTIONS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    set(icons "scalable^_${OPTIONS_SCALABLE}^^ico^_${OPTIONS_ICO}^^icns^_${OPTIONS_ICNS}^^1024x1024^_${OPTIONS_1024x1024}^^512x512^_${OPTIONS_512x512}^^256x256^_${OPTIONS_256x256}^^128x128^_${OPTIONS_128x128}^^64x64^_${OPTIONS_64x64}^^48x48^_${OPTIONS_48x48}^^32x32^_${OPTIONS_32x32}^^16x16^_${OPTIONS_16x16}")
    set_target_properties(${TARGET} PROPERTIES APPBASE_ICON "${icons}")
endfunction()

# install a target and more (APKs on Android, AppImage on Linux)
function(install_app TARGET)

    message(STATUS "QtAppBase: Install app ${TARGET}")

    if (APPLE)
        include(QtAppBaseCommon)
        set_target_properties(${TARGET} PROPERTIES MACOSX_BUNDLE_BUNDLE_NAME "${info.projectName}")
        set_target_properties(${TARGET} PROPERTIES MACOSX_BUNDLE_COPYRIGHT "${info.copyrightString}")
        set_target_properties(${TARGET} PROPERTIES MACOSX_BUNDLE_GUI_IDENTIFIER "${info.package}")
        set_target_properties(${TARGET} PROPERTIES MACOSX_BUNDLE_INFO_STRING "${info.description}")
        get_target_icon(${TARGET} ICNS ICNS_ICON)
        if(ICNS_ICON)
            get_filename_component(ICO_ICON_NAME "${ICNS_ICON}" NAME)
            set_target_properties(${TARGET} PROPERTIES MACOSX_BUNDLE_ICON_FILE "${ICO_ICON_NAME}")
            install(FILES "${ICNS_ICON}" DESTINATION "$<TARGET_FILE_NAME:${TARGET}>.app/Contents/Resources")
        endif()
    endif ()

    install(TARGETS ${TARGET} RUNTIME_DEPENDENCY_SET ${TARGET}runtime_set BUNDLE DESTINATION . LIBRARY DESTINATION ${CMAKE_INSTALL_BINDIR} RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

    if (ANDROID)
        include(AndroidDeploy)
        install_android(${TARGET})
    else ()
        if (Qt6Qml_DIR)
            qt_generate_deploy_qml_app_script(
                    TARGET ${TARGET}
                    OUTPUT_SCRIPT ${TARGET}_install_app_deploy_script
                    NO_UNSUPPORTED_PLATFORM_ERROR
            )
        else ()
            qt_generate_deploy_app_script(
                    TARGET ${TARGET}
                    OUTPUT_SCRIPT ${TARGET}_install_app_deploy_script
                    NO_UNSUPPORTED_PLATFORM_ERROR
            )
        endif ()

        install(SCRIPT ${${TARGET}_install_app_deploy_script})

        if (UNIX AND NOT APPLE)
            # TODO: On Unix qt_generate_deploy_qml_app_script is missing some libs. Install every Qt lib so no libs are missing
            install(CODE "
                        file (GLOB so_files LIST_DIRECTORIES false \"${QT6_INSTALL_PREFIX}/${QT6_INSTALL_LIBS}/*.so.*\")
                        message (STATUS \"Qt deployment is missing dependencies on Linux - Installing all Qt libs (resulting in a bigger package than necessary) \")
                        foreach (so_file IN LISTS so_files)
                        file (INSTALL \"\${so_file}\" DESTINATION \"${CMAKE_INSTALL_PREFIX}/${QT6_INSTALL_LIBS}\")
                        endforeach ()
                        message (STATUS \"Qt deployment is missing plugin dependencies on Linux - Installing all Qt plugins (resulting in a bigger package than necessary) \")
                        file (GLOB_RECURSE so_plugin_files LIST_DIRECTORIES false RELATIVE \"${QT6_INSTALL_PREFIX}/${QT6_INSTALL_PLUGINS}\" \"${QT6_INSTALL_PREFIX}/${QT6_INSTALL_PLUGINS}/*.so\")
                        foreach (so_plugin_file IN LISTS so_plugin_files)
                        get_filename_component(dir \"\${so_plugin_file}\" DIRECTORY)
                        file (INSTALL \"${QT6_INSTALL_PREFIX}/${QT6_INSTALL_PLUGINS}/\${so_plugin_file}\" DESTINATION \"${CMAKE_INSTALL_PREFIX}/${QT6_INSTALL_PLUGINS}/\${dir}\")
                        endforeach ()"
            )
        elseif (WIN32)
            if (CMAKE_RC_COMPILER)
                include(QtAppBaseCommon)
                set(AppIcon "")
                get_target_icon(${TARGET} ICO ICO_ICON)
                if (ICO_ICON)
                    set(AppIcon "IDI_ICON1 ICON \"${ICO_ICON}\"")
                else ()
                    message(WARNING "No \"ico\" icon file was registered for the target ${TARGET}. The exe won't show a custom icon!")
                endif ()
                set(INCLUDE_FILE_NAME "${TARGET}_file_name.h")
                file(GENERATE OUTPUT "${PROJECT_BINARY_DIR}/.qtappbase/rc/${INCLUDE_FILE_NAME}" CONTENT "#define APP_EXEC \"$<TARGET_FILE_NAME:${TARGET}>\\0\"\n#define APP_EXEC_BASE \"$<TARGET_FILE_BASE_NAME:${TARGET}>\\0\"" TARGET ${TARGET})
                configure_file("${current_dir}/win32resource.rc.in" "${PROJECT_BINARY_DIR}/.qtappbase/rc/${TARGET}_win32.rc" @ONLY)
                target_include_directories(${TARGET} PRIVATE "${PROJECT_BINARY_DIR}/.qtappbase/rc")
                target_sources(${TARGET} PRIVATE "${PROJECT_BINARY_DIR}/.qtappbase/rc/${TARGET}_win32.rc")
            endif ()
            install(RUNTIME_DEPENDENCY_SET ${TARGET}runtime_set
                    PRE_EXCLUDE_REGEXES
                    [=[api-ms-]=]
                    [=[ext-ms-]=]
                    [[kernel32\.dll]]
                    POST_EXCLUDE_REGEXES
                    [=[.*system32\/.*\.dll]=]
                    DIRECTORIES ${CONAN_RUNTIME_LIB_DIRS} "$ENV{MINGW_HOME}/bin"
            )
            #include(GetDependencies)
            #get_all_dependencies(${TARGET} alldeps NO_STATIC)
            #foreach (dep IN LISTS alldeps)
            #    install(IMPORTED_RUNTIME_ARTIFACTS ${dep} RUNTIME OPTIONAL)
            #endforeach ()
            include(QtIF)
            install_qtif(${TARGET})
        elseif (APPLE)
            cmake_path(GET MACDEPLOYQT_EXECUTABLE PARENT_PATH QT_BIN_PATH)
            cmake_path(GET QT_BIN_PATH PARENT_PATH QT_ROOT_PATH)
            install(RUNTIME_DEPENDENCY_SET ${TARGET}runtime_set
                DESTINATION
                "$<TARGET_FILE_NAME:${TARGET}>.app/Contents/Frameworks"
                PRE_EXCLUDE_REGEXES
                Qt.*\.framework
                POST_EXCLUDE_REGEXES
                "${QT_ROOT_PATH}/.*"
                DIRECTORIES ${CONAN_RUNTIME_LIB_DIRS})
        endif ()
    endif ()
    if (UNIX AND NOT ANDROID AND NOT APPLE)
        include(AppImage)
        install_appimage(${TARGET})
    endif ()
endfunction()

# qt_deploy_qml_imports() won't find qml modules outside Qt install dir. Use this function to add custom qml module locations
function(add_qml_import_path TARGET importPath)

    set(qml_import_paths "")
    # Get custom import paths provided during qt_add_qml_module call.
    get_target_property(qml_import_path ${TARGET} QT_QML_IMPORT_PATH)
    if (qml_import_path)
        list(APPEND qml_import_paths ${qml_import_path})
    endif ()

    list(APPEND qml_import_paths "${importPath}")
    set_target_properties(${TARGET} PROPERTIES QT_QML_IMPORT_PATH "${qml_import_paths}")
endfunction()

# The MODULE_TARGET has to be installed using install_qml_module(). It won't work otherwise
function(target_link_qml_module TARGET visibility MODULE_TARGET)

    set(qml_import_paths "")
    get_target_property(qml_import_path ${MODULE_TARGET} QT_QML_IMPORT_PATH)
    if (qml_import_path)
        list(APPEND qml_import_paths ${qml_import_path})
    else ()
        message(WARNING "QtAppBase: The MODULE_TARGET wasn't installed using install_qml_module().")
    endif ()

    target_link_libraries(${TARGET} ${visibility} ${MODULE_TARGET})
    add_qml_import_path(${TARGET} ${qml_import_paths})
endfunction()

# Link a Qml module that was created with ecm_add_qml_module
function(target_link_ecm_qml_module TARGET visibility MODULE_PACKAGE)

    find_package(${MODULE_PACKAGE} REQUIRED)
    add_qml_import_path(${TARGET} ${KDE_INSTALL_FULL_QMLDIR})
endfunction()
