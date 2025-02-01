set(current_dir ${CMAKE_CURRENT_LIST_DIR})

function(install_qtif TARGET)

    include(QtAppBaseCommon)
    find_program(ARCHIVEGEN_TOOL NAMES "archivegen")
    find_program(BINARYCREATOR_TOOL NAMES "binarycreator")
    find_program(INSTALLER_BASE NAMES "installerbase")

    get_target_property(APP_APPBASE_QTIF_SOURCE_DIR ${TARGET} APPBASE_QTIF_SOURCE_DIR)
    if (APP_APPBASE_QTIF_SOURCE_DIR)
        message(STATUS "QtAppBase: APPBASE_QTIF_SOURCE_DIR target property set - copying over provided Qt Installer dir structure")
    endif ()

    get_target_icon(${TARGET} ICO ICO_ICON)
    if(ICO_ICON)
        get_filename_component(ICO_ICON_NAME "${ICO_ICON}" NAME_WLE)
        set(IcoIcon "<InstallerApplicationIcon>${ICO_ICON_NAME}</InstallerApplicationIcon>")
    endif()

    get_target_first_icon(${TARGET} "32x32;48x48;64x64" WINDOW_ICON)
    if(WINDOW_ICON)
        get_filename_component(WINDOW_ICON_NAME "${WINDOW_ICON}" NAME)
        set(WindowIcon "<InstallerWindowIcon>${WINDOW_ICON_NAME}</InstallerWindowIcon>")
    endif()

    install(CODE "

        set(CMAKE_MODULE_PATH \"${CMAKE_MODULE_PATH}\")
        include(QtAppBase)

        file(REMOVE_RECURSE \"${CMAKE_INSTALL_PREFIX}/QtIF\")

        file(MAKE_DIRECTORY
        \"${CMAKE_INSTALL_PREFIX}/QtIF/config\"
        \"${CMAKE_INSTALL_PREFIX}/QtIF/packages\"
        \"${CMAKE_INSTALL_PREFIX}/QtIF/packages/${info.package}\"
        \"${CMAKE_INSTALL_PREFIX}/QtIF/packages/${info.package}/data\"
        \"${CMAKE_INSTALL_PREFIX}/QtIF/packages/${info.package}/meta\")

        if(${APP_APPBASE_QTIF_SOURCE_DIR})
            file(COPY \"${APP_APPBASE_QTIF_SOURCE_DIR}\" DESTINATION \"${CMAKE_INSTALL_PREFIX}/QtIF\")
        endif()

        if(EXISTS \"${ICO_ICON}\")
            file(COPY \"${ICO_ICON}\" DESTINATION \"${CMAKE_INSTALL_PREFIX}/QtIF/config\")
            set(AppIco \"${IcoIcon}\")
        endif()

        if(EXISTS \"${WINDOW_ICON}\")
            file(COPY \"${WINDOW_ICON}\" DESTINATION \"${CMAKE_INSTALL_PREFIX}/QtIF/config\")
            set(AppWindowIcon \"${WindowIcon}\")
        endif()

        file(COPY \"${CMAKE_INSTALL_PREFIX}/LICENSE\" DESTINATION \"${CMAKE_INSTALL_PREFIX}/QtIF/packages/${info.package}/meta\")

        set(AppName \"\$<TARGET_FILE_BASE_NAME:${TARGET}>\")
        set(AppExec \"\$<TARGET_FILE_NAME:${TARGET}>\")
        set(AppExecDir \"${CMAKE_INSTALL_BINDIR}\")

        parse_info(\"${PROJECT_SOURCE_DIR}/info.json\")
        string(TIMESTAMP TODAY \"%Y-%m-%d\")
        set(at @)
        set(OutName \"${info.projectName}-${info.versionString}-${CMAKE_SYSTEM_PROCESSOR}\")

        configure_file(\"${current_dir}/QtIF.config.in\" \"${CMAKE_INSTALL_PREFIX}/QtIF/config/config.xml\" @ONLY)
        configure_file(\"${current_dir}/QtIF.package.in\" \"${CMAKE_INSTALL_PREFIX}/QtIF/packages/${info.package}/meta/package.xml\" @ONLY)
        configure_file(\"${current_dir}/QtIF.install.qs.in\" \"${CMAKE_INSTALL_PREFIX}/QtIF/packages/${info.package}/meta/QtIF.install.qs\" @ONLY)

        if(EXISTS \"${CMAKE_INSTALL_FULL_BINDIR}\")
            execute_process(COMMAND ${ARCHIVEGEN_TOOL} -f 7z -c 5 \"QtIF/packages/${info.package}/data/${CMAKE_INSTALL_BINDIR}\" \"${CMAKE_INSTALL_BINDIR}\" WORKING_DIRECTORY \"${CMAKE_INSTALL_PREFIX}\" COMMAND_ERROR_IS_FATAL ANY)
        endif()
        if(EXISTS \"${CMAKE_INSTALL_FULL_LIBDIR}\")
            execute_process(COMMAND ${ARCHIVEGEN_TOOL} -f 7z -c 5 \"QtIF/packages/${info.package}/data/${CMAKE_INSTALL_LIBDIR}\" \"${CMAKE_INSTALL_LIBDIR}\" WORKING_DIRECTORY \"${CMAKE_INSTALL_PREFIX}\" COMMAND_ERROR_IS_FATAL ANY)
        endif()
        if(EXISTS \"${CMAKE_INSTALL_FULL_INCLUDEDIR}\")
            execute_process(COMMAND ${ARCHIVEGEN_TOOL} -f 7z -c 5 \"QtIF/packages/${info.package}/data/${CMAKE_INSTALL_INCLUDEDIR}\" \"${CMAKE_INSTALL_INCLUDEDIR}\" WORKING_DIRECTORY \"${CMAKE_INSTALL_PREFIX}\" COMMAND_ERROR_IS_FATAL ANY)
        endif()
        if(EXISTS \"${CMAKE_INSTALL_FULL_DATADIR}\")
            execute_process(COMMAND ${ARCHIVEGEN_TOOL} -f 7z -c 5 \"QtIF/packages/${info.package}/data/${CMAKE_INSTALL_DATADIR}\" \"${CMAKE_INSTALL_DATADIR}\" WORKING_DIRECTORY \"${CMAKE_INSTALL_PREFIX}\" COMMAND_ERROR_IS_FATAL ANY)
        endif()
        if(EXISTS \"${CMAKE_INSTALL_PREFIX}/plugins\")
            execute_process(COMMAND ${ARCHIVEGEN_TOOL} -f 7z -c 5 \"QtIF/packages/${info.package}/data/plugins\" \"plugins\" WORKING_DIRECTORY \"${CMAKE_INSTALL_PREFIX}\" COMMAND_ERROR_IS_FATAL ANY)
        endif()
        if(EXISTS \"${CMAKE_INSTALL_PREFIX}/qml\")
            execute_process(COMMAND ${ARCHIVEGEN_TOOL} -f 7z -c 5 \"QtIF/packages/${info.package}/data/qml\" \"qml\" WORKING_DIRECTORY \"${CMAKE_INSTALL_PREFIX}\" COMMAND_ERROR_IS_FATAL ANY)
        endif()
        if(EXISTS \"${CMAKE_INSTALL_PREFIX}/translations\")
            execute_process(COMMAND ${ARCHIVEGEN_TOOL} -f 7z -c 5 \"QtIF/packages/${info.package}/data/translations\" \"translations\" WORKING_DIRECTORY \"${CMAKE_INSTALL_PREFIX}\" COMMAND_ERROR_IS_FATAL ANY)
        endif()
        execute_process(COMMAND ${BINARYCREATOR_TOOL} -t \"${INSTALLER_BASE}\" -f -c QtIF/config/config.xml -p QtIF/packages \"\${OutName}-installer${CMAKE_EXECUTABLE_SUFFIX}\" WORKING_DIRECTORY \"${CMAKE_INSTALL_PREFIX}\" COMMAND_ERROR_IS_FATAL ANY)
    ")

endfunction()
