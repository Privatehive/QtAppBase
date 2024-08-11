set(current_dir ${CMAKE_CURRENT_LIST_DIR})

function(install_qtif TARGET)

    install(CODE "
					file(REMOVE_RECURSE \"${CMAKE_INSTALL_PREFIX}/QtIF\")

					file(MAKE_DIRECTORY
					\"${CMAKE_INSTALL_PREFIX}/QtIF/config\"
					\"${CMAKE_INSTALL_PREFIX}/QtIF/packages\"
					\"${CMAKE_INSTALL_PREFIX}/QtIF/packages/${info.package}\"
					\"${CMAKE_INSTALL_PREFIX}/QtIF/packages/${info.package}/data\"
					\"${CMAKE_INSTALL_PREFIX}/QtIF/packages/${info.package}/meta\")

                    file(COPY \"${CMAKE_INSTALL_PREFIX}/LICENSE\" DESTINATION \"${CMAKE_INSTALL_PREFIX}/QtIF/packages/${info.package}/meta\")

                    set(CMAKE_MODULE_PATH \"${CMAKE_MODULE_PATH}\")
                    set(AppExec \"\$<TARGET_FILE_NAME:${TARGET}>\")
                    set(AppExecDir \"${CMAKE_INSTALL_BINDIR}\")
                    include(QtAppBase)
                    parse_info(\"${PROJECT_SOURCE_DIR}/info.json\")
					string(TIMESTAMP TODAY \"%Y-%m-%d\")
					set(at @)

					configure_file(\"${current_dir}/QtIF.config.in\" \"${CMAKE_INSTALL_PREFIX}/QtIF/config/config.xml\" @ONLY)
					configure_file(\"${current_dir}/QtIF.package.in\" \"${CMAKE_INSTALL_PREFIX}/QtIF/packages/${info.package}/meta/package.xml\" @ONLY)

                    if(EXISTS \"${CMAKE_INSTALL_FULL_BINDIR}\")
                        execute_process(COMMAND archivegen${CMAKE_EXECUTABLE_SUFFIX} -f 7z -c 5 \"QtIF/packages/${info.package}/data/${CMAKE_INSTALL_BINDIR}\" \"${CMAKE_INSTALL_BINDIR}\" WORKING_DIRECTORY \"${CMAKE_INSTALL_PREFIX}\")
                    endif()
                    if(EXISTS \"${CMAKE_INSTALL_FULL_LIBDIR}\")
                        execute_process(COMMAND archivegen${CMAKE_EXECUTABLE_SUFFIX} -f 7z -c 5 \"QtIF/packages/${info.package}/data/${CMAKE_INSTALL_LIBDIR}\" \"${CMAKE_INSTALL_LIBDIR}\" WORKING_DIRECTORY \"${CMAKE_INSTALL_PREFIX}\")
                    endif()
                    if(EXISTS \"${CMAKE_INSTALL_FULL_INCLUDEDIR}\")
                        execute_process(COMMAND archivegen${CMAKE_EXECUTABLE_SUFFIX} -f 7z -c 5 \"QtIF/packages/${info.package}/data/${CMAKE_INSTALL_INCLUDEDIR}\" \"${CMAKE_INSTALL_INCLUDEDIR}\" WORKING_DIRECTORY \"${CMAKE_INSTALL_PREFIX}\")
                    endif()
					execute_process(COMMAND binarycreator${CMAKE_EXECUTABLE_SUFFIX} -f -c QtIF/config/config.xml -p QtIF/packages \"${info.projectName}-${info.versionString}-${CMAKE_SYSTEM_PROCESSOR}-installer${CMAKE_EXECUTABLE_SUFFIX}\" WORKING_DIRECTORY \"${CMAKE_INSTALL_PREFIX}\")
")

endfunction()
