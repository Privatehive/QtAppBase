set(current_dir ${CMAKE_CURRENT_LIST_DIR})
find_package(Qt6 REQUIRED COMPONENTS Core)

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

set(APPIMAGE_BASE_URL "https://conan.privatehive.de/artifactory/blob/appimage")

function(fixup_arch VAR ARCH_NAME)
	if(ARCH_NAME STREQUAL x86_64 OR ARCH_NAME STREQUAL amd64)
		set(${VAR} x86_64 PARENT_SCOPE)
	elseif(ARCH_NAME STREQUAL armv7l)
		set(${VAR} armhf PARENT_SCOPE)
	elseif(ARCH_NAME STREQUAL arm)
		set(${VAR} armv6 PARENT_SCOPE)
	elseif(ARCH_NAME STREQUAL aarch64)
		set(${VAR} aarch64 PARENT_SCOPE)
	elseif(ARCH_NAME STREQUAL i686)
		set(${VAR} i686 PARENT_SCOPE)
	else()
		set(${VAR} ${ARCH_NAME} PARENT_SCOPE)
	endif()
endfunction()

function(download url file)
	if(NOT EXISTS "${file}")
		file(DOWNLOAD "${url}" "${file}" SHOW_PROGRESS STATUS APPIMAGE_DOWNL_STATUS)
		list(GET APPIMAGE_DOWNL_STATUS 0 APPIMAGE_DOWNL_ERROR)
		list(GET APPIMAGE_DOWNL_STATUS 1 APPIMAGE_DOWNL_ERROR_MSG)
		if(APPIMAGE_DOWNL_ERROR)
			message(FATAL_ERROR "Could not download ${url}: ${APPIMAGE_DOWNL_ERROR_MSG}")
		endif()
		file(CHMOD "${file}" FILE_PERMISSIONS OWNER_READ GROUP_READ OWNER_WRITE GROUP_WRITE OWNER_EXECUTE GROUP_EXECUTE)
	endif()
endfunction()

function(install_appimage TARGET)

	fixup_arch(HOST_SYSTEM_ARCH ${CMAKE_HOST_SYSTEM_PROCESSOR})
	fixup_arch(SYSTEM_ARCH ${CMAKE_SYSTEM_PROCESSOR})

	set(APPIMAGE_TOOL_URL "${APPIMAGE_BASE_URL}/appimagetool-${HOST_SYSTEM_ARCH}.AppImage")
	set(APPIMAGE_RUNTIME_URL "${APPIMAGE_BASE_URL}/runtime-${SYSTEM_ARCH}")

	message(STATUS "Building AppImage on host arch ${HOST_SYSTEM_ARCH} targeting arch ${SYSTEM_ARCH}")

	set(APPIMAGE_TOOL "${PROJECT_BINARY_DIR}/appimagetool-${CMAKE_HOST_SYSTEM_PROCESSOR}.AppImage")
	download("${APPIMAGE_TOOL_URL}" "${APPIMAGE_TOOL}")

	set(APPIMAGE_RUNTIME "${PROJECT_BINARY_DIR}/runtime-${real_CMAKE_SYSTEM_PROCESSOR}")
	download("${APPIMAGE_RUNTIME_URL}" "${APPIMAGE_RUNTIME}")

	install(CODE "

					file(REMOVE_RECURSE \"${CMAKE_INSTALL_PREFIX}/AppDir\")
					file(COPY \"${CMAKE_INSTALL_PREFIX}\" DESTINATION \"${CMAKE_INSTALL_PREFIX}/AppDir\" PATTERN \"AppDir\" EXCLUDE)

					get_filename_component(INSTALL_PATH_NAME \"${CMAKE_INSTALL_PREFIX}\" NAME)
					file(RENAME \"${CMAKE_INSTALL_PREFIX}/AppDir/\${INSTALL_PATH_NAME}\" \"${CMAKE_INSTALL_PREFIX}/AppDir/usr\")

					file(MAKE_DIRECTORY
					\"${CMAKE_INSTALL_PREFIX}/AppDir/usr/bin\"
					\"${CMAKE_INSTALL_PREFIX}/AppDir/usr/lib\"
					\"${CMAKE_INSTALL_PREFIX}/AppDir/usr/share/applications\"
					\"${CMAKE_INSTALL_PREFIX}/AppDir/usr/share/icons\")

					set(AppName \"\$<TARGET_FILE_BASE_NAME:${TARGET}>\")
					set(AppExec \"\$<TARGET_FILE_NAME:${TARGET}>\")
					set(AppIcon \"\$<TARGET_FILE_BASE_NAME:${TARGET}>\")
					configure_file(\"${current_dir}/QtAppBase.desktop.in\" \"${CMAKE_INSTALL_PREFIX}/AppDir/usr/share/applications/\$<TARGET_FILE_BASE_NAME:${TARGET}>.desktop\" @ONLY)

					file(DOWNLOAD \"https://upload.wikimedia.org/wikipedia/commons/0/00/Cross-image.svg\" \"${CMAKE_INSTALL_PREFIX}/AppDir/\${AppIcon}.svg\")

					execute_process(COMMAND ${CMAKE_COMMAND} -E create_symlink \"usr/bin/\$<TARGET_FILE_NAME:${TARGET}>\" \"AppRun\" WORKING_DIRECTORY \"${CMAKE_INSTALL_PREFIX}/AppDir\")
					execute_process(COMMAND ${CMAKE_COMMAND} -E create_symlink \"usr/share/applications/\$<TARGET_FILE_BASE_NAME:${TARGET}>.desktop\" \"\$<TARGET_FILE_BASE_NAME:${TARGET}>.desktop\" WORKING_DIRECTORY \"${CMAKE_INSTALL_PREFIX}/AppDir\")

					execute_process(COMMAND ${APPIMAGE_TOOL} --no-appstream --runtime-file \"${APPIMAGE_RUNTIME}\" ./AppDir WORKING_DIRECTORY \"${CMAKE_INSTALL_PREFIX}\")

					if(\"${SYSTEM_ARCH}\" STREQUAL \"armv6\")
						execute_process(COMMAND ${CMAKE_COMMAND} -E rename \"\$<TARGET_FILE_BASE_NAME:${TARGET}>-armhf.AppImage\" \"\$<TARGET_FILE_BASE_NAME:${TARGET}>-armv6.AppImage\" WORKING_DIRECTORY \"${CMAKE_INSTALL_PREFIX}\")
					endif()
")

endfunction()
