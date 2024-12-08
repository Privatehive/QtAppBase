set(current_dir ${CMAKE_CURRENT_LIST_DIR})

#AppDir
#└── AppRun
#└── your_app.desktop
#└── your_app.png
#└── usr
#    ├── bin
#    │   └── your_app
#    ├── lib
#    └── share
#        ├── applications
#        │   └── your_app.desktop
#        └── icons
#            └── <theme>
#                 └── <resolution>
#                     └── your_app.png

# convert from cmake arch to appimage arch
function(fixup_arch VAR ARCH_NAME)

    if (ARCH_NAME STREQUAL x86_64 OR ARCH_NAME STREQUAL amd64)
        set(${VAR} x86_64 PARENT_SCOPE)
    elseif (ARCH_NAME STREQUAL armv7l)
        set(${VAR} armhf PARENT_SCOPE)
    elseif (ARCH_NAME STREQUAL arm)
        set(${VAR} armv6 PARENT_SCOPE)
    elseif (ARCH_NAME STREQUAL aarch64)
        set(${VAR} aarch64 PARENT_SCOPE)
    elseif (ARCH_NAME STREQUAL i686)
        set(${VAR} i686 PARENT_SCOPE)
    else ()
        set(${VAR} ${ARCH_NAME} PARENT_SCOPE)
    endif ()
endfunction()

function(install_appimage TARGET)

    include(QtAppBaseCommon)
    fixup_arch(HOST_SYSTEM_ARCH ${CMAKE_HOST_SYSTEM_PROCESSOR}) # the building system
    fixup_arch(SYSTEM_ARCH ${CMAKE_SYSTEM_PROCESSOR})

    message(STATUS "QtAppBase: Building AppImage on host arch ${HOST_SYSTEM_ARCH} targeting arch ${SYSTEM_ARCH}")

    find_program(APPIMAGE_TOOL NAMES "appimagetool" "appimagetool-${HOST_SYSTEM_ARCH}.AppImage")
    find_program(APPIMAGE_RUNTIME NAMES "runtime-${SYSTEM_ARCH}")

    # https://specifications.freedesktop.org/desktop-entry-spec/latest/recognized-keys.html
    # categories: https://specifications.freedesktop.org/menu-spec/latest/category-registry.html

    set(MIME_OUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/.qtappbase/mime/packages")
    set(ICONS_OUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/.qtappbase/hicolor")

    create_mime_mappings(${TARGET} "${info.projectName}" "${MIME_OUT_DIR}")
    create_appimage_icons_dir(${TARGET} "${info.projectName}" "${ICONS_OUT_DIR}" PRIMARY_ICON)

    install(CODE "
        # Make info.json available
        set(CMAKE_MODULE_PATH \"${CMAKE_MODULE_PATH}\")
        include(QtAppBase)
        parse_info(\"${PROJECT_SOURCE_DIR}/info.json\")
        string(TIMESTAMP TODAY \"%Y-%m-%d\")
        set(at @)
        set(OutName \"${info.projectName}-${info.versionString}-${CMAKE_SYSTEM_PROCESSOR}\")

        set(AppName \"\${info.projectName}\")
        set(AppExec \"\$<TARGET_FILE_NAME:${TARGET}>\")

        file(REMOVE_RECURSE \"${CMAKE_INSTALL_PREFIX}/AppDir\")
        file(COPY \"${CMAKE_INSTALL_PREFIX}\" DESTINATION \"${CMAKE_INSTALL_PREFIX}/AppDir\" PATTERN \"AppDir\" EXCLUDE)

        get_filename_component(INSTALL_PATH_NAME \"${CMAKE_INSTALL_PREFIX}\" NAME)
        file(RENAME \"${CMAKE_INSTALL_PREFIX}/AppDir/\${INSTALL_PATH_NAME}\" \"${CMAKE_INSTALL_PREFIX}/AppDir/usr\")

        file(MAKE_DIRECTORY
        \"${CMAKE_INSTALL_PREFIX}/AppDir/usr/bin\"
        \"${CMAKE_INSTALL_PREFIX}/AppDir/usr/lib\"
        \"${CMAKE_INSTALL_PREFIX}/AppDir/usr/lib/fonts\"
        \"${CMAKE_INSTALL_PREFIX}/AppDir/usr/share/applications\")

        if(EXISTS \"${MIME_OUT_DIR}\")
            file(COPY \"${MIME_OUT_DIR}\" DESTINATION \"${CMAKE_INSTALL_PREFIX}/AppDir/usr/share/mime\")
        endif()

        if(EXISTS \"${ICONS_OUT_DIR}\")
            file(COPY \"${ICONS_OUT_DIR}\" DESTINATION \"${CMAKE_INSTALL_PREFIX}/AppDir/usr/share/icons\")
            get_filename_component(ICON_FILE \"${PRIMARY_ICON}\" NAME)
            execute_process(COMMAND ${CMAKE_COMMAND} -E create_symlink \"usr/share/icons/hicolor/${PRIMARY_ICON}\" \"\${ICON_FILE}\" WORKING_DIRECTORY \"${CMAKE_INSTALL_PREFIX}/AppDir\")
            set(AppIcon \"Icon=\${AppName}\")
        endif()

        configure_file(\"${current_dir}/AppImage.desktop.in\" \"${CMAKE_INSTALL_PREFIX}/AppDir/usr/share/applications/\${AppName}.desktop\" @ONLY)

        # DejaVu font
        file(DOWNLOAD \"http://sourceforge.net/projects/dejavu/files/dejavu/2.37/dejavu-sans-ttf-2.37.zip\" \"${PROJECT_BINARY_DIR}/dejavu-sans-ttf-2.37.zip\")
        execute_process(COMMAND ${CMAKE_COMMAND} -E tar xf \"${PROJECT_BINARY_DIR}/dejavu-sans-ttf-2.37.zip\" WORKING_DIRECTORY \"${PROJECT_BINARY_DIR}\")
        execute_process(COMMAND ${CMAKE_COMMAND} -E copy \"${PROJECT_BINARY_DIR}/dejavu-sans-ttf-2.37/ttf/DejaVuSans.ttf\" \"${CMAKE_INSTALL_PREFIX}/AppDir/usr/lib/fonts\")

        execute_process(COMMAND ${CMAKE_COMMAND} -E create_symlink \"usr/bin/\${AppExec}\" \"AppRun\" WORKING_DIRECTORY \"${CMAKE_INSTALL_PREFIX}/AppDir\")
        execute_process(COMMAND ${CMAKE_COMMAND} -E create_symlink \"usr/share/applications/\${AppName}.desktop\" \"\${AppName}.desktop\" WORKING_DIRECTORY \"${CMAKE_INSTALL_PREFIX}/AppDir\")

        execute_process(COMMAND ${APPIMAGE_TOOL} --no-appstream --runtime-file \"${APPIMAGE_RUNTIME}\" ./AppDir \${OutName}.AppImage WORKING_DIRECTORY \"${CMAKE_INSTALL_PREFIX}\" COMMAND_ERROR_IS_FATAL ANY)
    ")

endfunction()
