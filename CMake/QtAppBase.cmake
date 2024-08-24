cmake_minimum_required(VERSION 3.21.1)
set(current_dir ${CMAKE_CURRENT_LIST_DIR})

macro(parse_info INFO_FILE)

    include(JSONParser)
    file(READ "${INFO_FILE}" jsonInfo)
    sbeParseJson(info jsonInfo)

    string(TOLOWER "${info.projectName}" info.projectNameLowerCase)
    set(info.package "${info.domain}.${info.projectNameLowerCase}")
    string(REPLACE "." "/" info.packagejni "${info.package}")

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
        message(NOTICE "Missing LICENSE file in project folder. Creating a placeholder.")
        file(WRITE "${PROJECT_SOURCE_DIR}/LICENSE" "TODO")
    endif ()

    if (NOT EXISTS "${PROJECT_SOURCE_DIR}/info.json")
        message(NOTICE "Missing info.json file in project folder. Creating a generic one.")
        string(TIMESTAMP current_year %Y)
        string(TIMESTAMP timestamp_id %s UTC)
        file(WRITE "${PROJECT_SOURCE_DIR}/info.json" "{
  \"version\": {
    \"major\": 1,
    \"minor\": 0,
    \"patch\": 0,
    \"snapshot\": true
  },
  \"projectName\": \"GenericProject\",
  \"projectDescription\": \"-\",
  \"projectId\": \"${timestamp_id}\",
  \"vendor\": \"-\",
  \"contact\": \"-\",
  \"domain\": \"-\",
  \"copyrightYear\": \"${current_year}\",
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
    file(WRITE "${PROJECT_BINARY_DIR}/.qtappbase/info.h" "")
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
            message(STATUS "Configuring release/signed APK, AAB")
            set(QT_ANDROID_DEPLOY_RELEASE ON)
            set(QT_ANDROID_SIGN_APK ON)
            set(QT_ANDROID_SIGN_AAB ON)
        else ()
            message(STATUS "Configuring debug/debug-signed APK, AAB")
            set(QT_ANDROID_DEPLOY_RELEASE OFF)
            set(QT_ANDROID_SIGN_APK OFF)
            set(QT_ANDROID_SIGN_AAB OFF)
        endif ()
        #message(STATUS "Run target 'apk' to build APK")
        message(STATUS "Run target 'aab' to build AAB")
    endif ()

    find_package(Qt6 REQUIRED Core)
    find_package(Qt6 COMPONENTS Qml)
    if (Qt6Qml_DIR)
        if (QT_KNOWN_POLICY_QTP0001)
            qt_policy(SET QTP0001 NEW)
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
    get_target_property(CURRENT_PUBLIC_HEADERsssd ${TARGET} PUBLIC_HEADER)
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
            message(STATUS "  found resource target ${resource_target_name}")
            list(APPEND install_targest "${resource_target_name}")
        endif ()
    endforeach ()
    set(${OUT} ${install_targest} PARENT_SCOPE)
endfunction()

function(_combine_with_init_targets TARGET OUT)
    set(install_targest ${TARGET})
    set(init_target_name "${TARGET}_init")
    if (TARGET ${init_target_name})
        message(STATUS "  found init target ${init_target_name}")
        list(APPEND install_targest "${init_target_name}")
    endif ()
    set(${OUT} ${install_targest} PARENT_SCOPE)
endfunction()

function(install_qt_library TARGET)

    message(STATUS "install_qt_library ${TARGET}")
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

    message(STATUS "install_qml_module ${TARGET}")
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

function(gen_version_code VAR)

    set(ARG_VERSION_CODE "0")

    if (DEFINED PROJECT_VERSION_MAJOR AND NOT PROJECT_VERSION_MAJOR STREQUAL "")
        if (PROJECT_VERSION_MAJOR LESS "2100" AND PROJECT_VERSION_MAJOR GREATER "-1")
            math(EXPR ARG_VERSION_CODE "${ARG_VERSION_CODE} + ${PROJECT_VERSION_MAJOR} * 1000000")
        else ()
            message(FATAL_ERROR "PROJECT_VERSION_MAJOR exceeding the allowed range of [0, 2099]")
        endif ()
    endif ()
    if (DEFINED PROJECT_VERSION_MINOR AND NOT PROJECT_VERSION_MINOR STREQUAL "")
        if (PROJECT_VERSION_MINOR LESS "100" AND PROJECT_VERSION_MINOR GREATER "-1")
            math(EXPR ARG_VERSION_CODE "${ARG_VERSION_CODE} + ${PROJECT_VERSION_MINOR} * 10000")
        else ()
            message(FATAL_ERROR "PROJECT_VERSION_MINOR exceeding the allowed range of [0, 99]")
        endif ()
    endif ()
    if (DEFINED PROJECT_VERSION_PATCH AND NOT PROJECT_VERSION_PATCH STREQUAL "")
        if (PROJECT_VERSION_PATCH LESS "100" AND PROJECT_VERSION_PATCH GREATER "-1")
            math(EXPR ARG_VERSION_CODE "${ARG_VERSION_CODE} + ${PROJECT_VERSION_PATCH} * 100")
        else ()
            message(FATAL_ERROR "PROJECT_VERSION_PATCH exceeding the allowed range of [0, 99]")
        endif ()
    endif ()
    if (DEFINED PROJECT_VERSION_TWEAK AND NOT PROJECT_VERSION_TWEAK STREQUAL "")
        if (PROJECT_VERSION_TWEAK LESS "10" AND PROJECT_VERSION_TWEAK GREATER "-1")
            math(EXPR ARG_VERSION_CODE "${ARG_VERSION_CODE} + ${PROJECT_VERSION_TWEAK} * 10")
        else ()
            message(FATAL_ERROR "PROJECT_VERSION_TWEAK exceeding the allowed range of [0, 9]")
        endif ()
    endif ()
    if (CMAKE_ANDROID_ARCH_ABI STREQUAL "arm64-v8a")
        math(EXPR ARG_VERSION_CODE "${ARG_VERSION_CODE} + 1")
    elseif (CMAKE_ANDROID_ARCH_ABI STREQUAL "armeabi-v7a" AND NOT CMAKE_ANDROID_ARM_NEON)
        math(EXPR ARG_VERSION_CODE "${ARG_VERSION_CODE} + 2")
    elseif (CMAKE_ANDROID_ARCH_ABI STREQUAL "armeabi-v7a" AND CMAKE_ANDROID_ARM_NEON)
        math(EXPR ARG_VERSION_CODE "${ARG_VERSION_CODE} + 3")
    elseif (CMAKE_ANDROID_ARCH_ABI STREQUAL "armeabi-v6")
        math(EXPR ARG_VERSION_CODE "${ARG_VERSION_CODE} + 4")
    elseif (CMAKE_ANDROID_ARCH_ABI STREQUAL "armeabi")
        math(EXPR ARG_VERSION_CODE "${ARG_VERSION_CODE} + 5")
    elseif (CMAKE_ANDROID_ARCH_ABI STREQUAL "mips")
        math(EXPR ARG_VERSION_CODE "${ARG_VERSION_CODE} + 6")
    elseif (CMAKE_ANDROID_ARCH_ABI STREQUAL "mips64")
        math(EXPR ARG_VERSION_CODE "${ARG_VERSION_CODE} + 7")
    elseif (CMAKE_ANDROID_ARCH_ABI STREQUAL "x86")
        math(EXPR ARG_VERSION_CODE "${ARG_VERSION_CODE} + 8")
    elseif (CMAKE_ANDROID_ARCH_ABI STREQUAL "x86_64")
        math(EXPR ARG_VERSION_CODE "${ARG_VERSION_CODE} + 9")
    else ()
        message(WARNING "Couldn't read valid CMAKE_ANDROID_ARCH_ABI. The VERSION_CODE won't be distinguishable between different abi's")
    endif ()

    set(${VAR} ${ARG_VERSION_CODE} PARENT_SCOPE)
endfunction()

# install a target and more (APKs on Android, AppImage on Linux)
function(install_app TARGET)

    message(STATUS "install_app ${TARGET}")
    install(TARGETS ${TARGET} BUNDLE DESTINATION . LIBRARY DESTINATION ${CMAKE_INSTALL_BINDIR} RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

    if (ANDROID)
        get_target_property(APP_ANDROID_PACKAGE_SOURCE_DIR ${TARGET} QT_ANDROID_PACKAGE_SOURCE_DIR)
        if (APP_ANDROID_PACKAGE_SOURCE_DIR)
            message(STATUS "QT_ANDROID_PACKAGE_SOURCE_DIR target property already set - using provided AndroidManifest.xml")
            if (EXISTS "${APP_ANDROID_PACKAGE_SOURCE_DIR}/AndroidManifest.xml.in")
                configure_file("${APP_ANDROID_PACKAGE_SOURCE_DIR}/AndroidManifest.xml.in" "${APP_ANDROID_PACKAGE_SOURCE_DIR}/AndroidManifest.xml" @ONLY)
            endif ()
        else ()
            configure_file("${current_dir}/AndroidManifest.xml.in" "${CMAKE_CURRENT_BINARY_DIR}/android_package_src/AndroidManifest.xml" @ONLY)
            set_target_properties(${TARGET} PROPERTIES QT_ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_BINARY_DIR}/android_package_src")
        endif ()
        gen_version_code(VERSION_CONDE)
        set_target_properties(${TARGET} PROPERTIES QT_ANDROID_VERSION_CODE "${VERSION_CONDE}")
        set_target_properties(${TARGET} PROPERTIES QT_ANDROID_VERSION_NAME "${PROJECT_VERSION}")
        message(STATUS "Using Android Version Code '${VERSION_CONDE}' and Version Name '${PROJECT_VERSION}'")
        install(FILES "${CMAKE_CURRENT_BINARY_DIR}/android-build/$<TARGET_NAME:${TARGET}>.apk" DESTINATION .)
        install(CODE "execute_process(COMMAND adb install \"${CMAKE_CURRENT_BINARY_DIR}/android-build/$<TARGET_NAME:${TARGET}>.apk\")")
    else ()
        qt_generate_deploy_qml_app_script(
                TARGET ${TARGET}
                OUTPUT_SCRIPT ${TARGET}_install_app_deploy_script
                NO_UNSUPPORTED_PLATFORM_ERROR
        )
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
								 message(STATUS \"---aasdf-${QT6_INSTALL_PLUGINS}---${QT6_INSTALL_PREFIX}------\${so_plugin_files}\")
								 foreach (so_plugin_file IN LISTS so_plugin_files)
								 get_filename_component(dir \"\${so_plugin_file}\" DIRECTORY)
								 file (INSTALL \"${QT6_INSTALL_PREFIX}/${QT6_INSTALL_PLUGINS}/\${so_plugin_file}\" DESTINATION \"${CMAKE_INSTALL_PREFIX}/${QT6_INSTALL_PLUGINS}/\${dir}\")
								 endforeach ()
								 ")
        else (WIN32)
            set(MinGwHome "$ENV{MINGW_HOME}")
            if (EXISTS "${MinGwHome}")
                string(REPLACE "\\" "/" MinGwHomeFw "${MinGwHome}")
                install(CODE "
set(MINGW_BIN \"${MinGwHomeFw}/bin\")
file (GET_RUNTIME_DEPENDENCIES RESOLVED_DEPENDENCIES_VAR resolved UNRESOLVED_DEPENDENCIES_VAR unresolved EXECUTABLES \$<TARGET_FILE:${TARGET}> DIRECTORIES \"\${MINGW_BIN}\")
foreach (dll_file IN LISTS resolved)
cmake_path(IS_PREFIX MINGW_BIN \"\${dll_file}\" is_mingw_dll)
if(is_mingw_dll)
file (INSTALL \"\${dll_file}\" DESTINATION \"${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}\")
endif()
endforeach ()
            ")
            endif ()
            include(GetDependencies)
            get_all_dependencies(${TARGET} alldeps NO_STATIC)
            foreach (dep IN LISTS alldeps)
                install(IMPORTED_RUNTIME_ARTIFACTS ${dep} RUNTIME OPTIONAL)
            endforeach ()
            include(QtIF)
            install_qtif(${TARGET})
        endif ()
    endif ()
    if (UNIX AND NOT ANDROID AND NOT APPLE)
        include(AppImage)
        install_appimage(${TARGET})
        include(QtIF)
        install_qtif(${TARGET})
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
        message(WARNING "The MODULE_TARGET wasn't installed using install_qml_module().")
    endif ()

    target_link_libraries(${TARGET} ${visibility} ${MODULE_TARGET})
    add_qml_import_path(${TARGET} ${qml_import_paths})
endfunction()

# Link a Qml module that was created with ecm_add_qml_module
function(target_link_ecm_qml_module TARGET visibility MODULE_PACKAGE)

    find_package(${MODULE_PACKAGE} REQUIRED)
    add_qml_import_path(${TARGET} ${KDE_INSTALL_FULL_QMLDIR})
endfunction()
