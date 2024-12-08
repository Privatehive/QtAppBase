set(current_dir ${CMAKE_CURRENT_LIST_DIR})

# convert from cmake arch to pkbuild arch
function(fixup_arch VAR ARCH_NAME)

    if (ARCH_NAME STREQUAL x86_64 OR ARCH_NAME STREQUAL amd64)
        set(${VAR} x86_64 PARENT_SCOPE)
    elseif (ARCH_NAME STREQUAL armv7l)
        set(${VAR} armv7h PARENT_SCOPE)
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

function(install_pkgbuild TARGET)

    include(QtAppBaseCommon)
    fixup_arch(SYSTEM_ARCH ${CMAKE_SYSTEM_PROCESSOR})

    message(STATUS "QtAppBase: Building PKGBUILD targeting arch ${SYSTEM_ARCH}")

    find_program(MAKEPKG_TOOL NAMES "makepkg")

    set(MIME_OUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/.qtappbase/mime/packages")

    create_mime_mappings(${TARGET} "${MIME_OUT_DIR}")

    install(CODE "
        # Make info.json available
        set(CMAKE_MODULE_PATH \"${CMAKE_MODULE_PATH}\")
        include(QtAppBase)
        parse_info(\"${PROJECT_SOURCE_DIR}/info.json\")
        string(TIMESTAMP TODAY \"%Y-%m-%d\")
        set(at @)
        set(OUT_NAME \"${info.projectName}-${info.versionString}-${CMAKE_SYSTEM_PROCESSOR}\")
        set(OUT_DIR \"${CMAKE_INSTALL_PREFIX}/makepkg\")
        set(OUT_DIR_OPT \"${CMAKE_INSTALL_PREFIX}/makepkg/opt/\${info.projectName}\")

        file(REMOVE_RECURSE \"\${OUT_DIR}\")
        file(COPY \"${CMAKE_INSTALL_PREFIX}\" DESTINATION \"\${OUT_DIR}/opt\" PATTERN \"makepkg\" EXCLUDE)

        get_filename_component(INSTALL_PATH_NAME \"${CMAKE_INSTALL_PREFIX}\" NAME)
        file(RENAME \"\${OUT_DIR}/opt/\${INSTALL_PATH_NAME}\" \"\${OUT_DIR_OPT}\")

        if(EXISTS \"${MIME_OUT_DIR}\")
            file(COPY \"${MIME_OUT_DIR}\" DESTINATION \"\${OUT_DIR}/usr/share/mime\")
        endif()

        set(AppName \"\${info.projectName}\")
        set(AppExec \"/opt/\${info.projectName}/\$<TARGET_FILE_NAME:${TARGET}>\")
        set(AppArch \"${SYSTEM_ARCH}\")

        configure_file(\"${current_dir}/AppImage.desktop.in\" \"\${OUT_DIR}/usr/share/applications/\${AppName}.desktop\" @ONLY)

        # Default AppImage icon
        file(DOWNLOAD \"https://upload.wikimedia.org/wikipedia/commons/0/00/Cross-image.svg\" \"\${OUT_DIR}/AppDir/\${AppName}.svg\")

        file(GLOB_RECURSE FILES_LIST LIST_DIRECTORIES false RELATIVE \"\${OUT_DIR}\" \"\${OUT_DIR}/*\")

        execute_process(COMMAND ${CMAKE_COMMAND} -E tar cf pkg.tar.gz \"makepkg\" WORKING_DIRECTORY \"${CMAKE_INSTALL_PREFIX}\")

        list(JOIN \"FILES_LIST\" \" \" FILES)

        configure_file(\"${current_dir}/PKGBUILD.in\" \"${CMAKE_INSTALL_PREFIX}/PKGBUILD\" @ONLY)

        execute_process(COMMAND ${MAKEPKG_TOOL} -m -f -C -s --noconfirm --skipinteg WORKING_DIRECTORY \"\${CMAKE_INSTALL_PREFIX}\" COMMAND_ERROR_IS_FATAL ANY)
    ")

endfunction()
