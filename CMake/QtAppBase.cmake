cmake_minimum_required(VERSION 3.19)
set(current_dir ${CMAKE_CURRENT_LIST_DIR})

macro(qt_app_project_setup PROJECT_SETUP_INFO_VAR)

	include(JSONParser)

	if(NOT EXISTS "${PROJECT_SOURCE_DIR}/LICENSE")
		message(NOTICE "Missing LICENSE file in project folder. Creating a generic one.")
		file(WRITE "${PROJECT_SOURCE_DIR}/LICENSE" "")
	endif()

	if(NOT EXISTS "${PROJECT_SOURCE_DIR}/info.json")
		message(NOTICE "Missing info.json file in project folder. Creating a generic one.")
		string(TIMESTAMP current_year %Y)
		file(WRITE "${PROJECT_SOURCE_DIR}/info.json" "{
  \"version\": {
    \"major\": 1,
    \"minor\": 0,
    \"patch\": 0,
    \"snapshot\": true
  },
  \"projectName\": \"GenericProject\",
  \"projectDescription\": \"-\",
  \"vendor\": \"-\",
  \"contact\": \"-\",
  \"domain\": \"-\",
  \"copyrightYear\": \"${current_year}\",
  \"repository\": \"-\",
  \"topics\": [],
  \"homepage\": \"-\",
  \"license\": \"-\"
}")
	endif()

	# Parse the info.json and write a info.h file
	file(READ "${PROJECT_SOURCE_DIR}/info.json" jsonInfo)
	sbeParseJson(info jsonInfo)

	set(${PROJECT_SETUP_INFO_VAR} "${info.projectName}" "VERSION" "${info.version.major}.${info.version.minor}.${info.version.patch}" "DESCRIPTION" "${info.projectDescription}" "HOMEPAGE_URL" "${info.repository}" "LANGUAGES" "C" "CXX")
endmacro()

macro(qt_app_setup)

	set(CMAKE_CXX_STANDARD 17)
	set(CMAKE_CXX_STANDARD_REQUIRED ON)

	# Configure a header file to pass some of the CMake settings to the source code.
	include_directories("${PROJECT_BINARY_DIR}")
	file(WRITE "${PROJECT_BINARY_DIR}/info.h" "")
	foreach(var ${info})
		string(TOUPPER "${var}" UPPER_VAR)
		string(REPLACE "." "_" UPPER_VAR "${UPPER_VAR}")
		list(LENGTH ${var} LIST_LEN)
		if(LIST_LEN EQUAL 1)
			if(${${var}} MATCHES "^[0-9]+$")
				file(APPEND "${PROJECT_BINARY_DIR}/info.h" "#define ${UPPER_VAR} ${${var}}\n")
			else()
				file(APPEND "${PROJECT_BINARY_DIR}/info.h" "#define ${UPPER_VAR} \"${${var}}\"\n")
			endif()
		endif()
	endforeach()

	if(ANDROID)
		set(QT_ENABLE_VERBOSE_DEPLOYMENT OFF) # If ON leads to sign error
		#set(QT_NO_GLOBAL_APK_TARGET_PART_OF_ALL ON)
		if(CMAKE_BUILD_TYPE STREQUAL "Release" OR CMAKE_BUILD_TYPE STREQUAL "MinSizeRel")
			message(STATUS "Configuring release/signed APK, AAB")
			set(QT_ANDROID_DEPLOY_RELEASE ON)
			set(QT_ANDROID_SIGN_APK ON)
			set(QT_ANDROID_SIGN_AAB ON)
		else()
			message(STATUS "Configuring debug/debug-signed APK, AAB")
			set(QT_ANDROID_DEPLOY_RELEASE OFF)
			set(QT_ANDROID_SIGN_APK OFF)
			set(QT_ANDROID_SIGN_AAB OFF)
		endif()
		#message(STATUS "Run target 'apk' to build APK")
		message(STATUS "Run target 'aab' to build AAB")
	endif()

	find_package(Qt6 REQUIRED COMPONENTS Core)

	qt_standard_project_setup()

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
								 include (CPack)
								 )
endmacro()

# https://doc.qt.io/qt-6/qt-query-qml-module.html#example
# Qt can't install qml modules yet. We have to provide a solution.
function(install_qml_module TARGET)

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

	# Install the QML module backing library
	set(staging_prefix ".")
	install(TARGETS ${TARGET}
					EXPORT ${TARGET}-Targets
					ARCHIVE DESTINATION "${staging_prefix}/${CMAKE_INSTALL_LIBDIR}"
					LIBRARY DESTINATION "${staging_prefix}/${CMAKE_INSTALL_LIBDIR}"
					RUNTIME DESTINATION "${staging_prefix}/${CMAKE_INSTALL_BINDIR}"
					PUBLIC_HEADER DESTINATION "${staging_prefix}/${CMAKE_INSTALL_INCLUDEDIR}"
					)
	set(module_dir "${staging_prefix}/qml/${module_target_path}")

	install(EXPORT ${TARGET}-Targets
					DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/${TARGET}"
					)

	file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}Config.cmake.in" "include (CMakeFindDependencyMacro)
							# TODO find_package not complete
							find_package(Qt6 REQUIRED COMPONENTS Core Qml Gui Quick)
							include(\"\${CMAKE_CURRENT_LIST_DIR}/${TARGET}-Targets.cmake\")

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

	# Install the QML module runtime loadable plugin
	install(TARGETS "${module_plugin_target}"
					LIBRARY DESTINATION "${module_dir}"
					RUNTIME DESTINATION "${module_dir}"
					)

	# Install the QML module meta information.
	install(FILES "${module_qmldir}" DESTINATION "${module_dir}")
	install(FILES "${module_typeinfo}" DESTINATION "${module_dir}")

	# Install QML files, possibly renamed.
	list(LENGTH module_qml_files num_files)
	math(EXPR last_index "${num_files} - 1")
	if(${last_index} GREATER_EQUAL 0)
		foreach(i RANGE 0 ${last_index})
			list(GET module_qml_files ${i} src_file)
			list(GET qml_files_deploy_paths ${i} deploy_path)
			get_filename_component(dst_name "${deploy_path}" NAME)
			get_filename_component(dest_dir "${deploy_path}" DIRECTORY)
			install(FILES "${src_file}" DESTINATION "${module_dir}/${dest_dir}" RENAME "${dst_name}")
		endforeach()
	endif()

	# Install resources, possibly renamed.
	list(LENGTH module_resources num_files)
	math(EXPR last_index "${num_files} - 1")
	if(${last_index} GREATER_EQUAL 0)
		foreach(i RANGE 0 ${last_index})
			list(GET module_resources ${i} src_file)
			list(GET resources_deploy_paths ${i} deploy_path)
			get_filename_component(dst_name "${deploy_path}" NAME)
			get_filename_component(dest_dir "${deploy_path}" DIRECTORY)
			install(FILES "${src_file}" DESTINATION "${module_dir}/${dest_dir}" RENAME "${dst_name}")
		endforeach()
	endif()
endfunction()

function(gen_version_code VAR)

	set(ARG_VERSION_CODE "0")

	if(DEFINED PROJECT_VERSION_MAJOR AND NOT PROJECT_VERSION_MAJOR STREQUAL "")
		if(PROJECT_VERSION_MAJOR LESS "2100" AND PROJECT_VERSION_MAJOR GREATER "-1")
			math(EXPR ARG_VERSION_CODE "${ARG_VERSION_CODE} + ${PROJECT_VERSION_MAJOR} * 1000000")
		else()
			message(FATAL_ERROR "PROJECT_VERSION_MAJOR exceeding the allowed range of [0, 2099]")
		endif()
	endif()
	if(DEFINED PROJECT_VERSION_MINOR AND NOT PROJECT_VERSION_MINOR STREQUAL "")
		if(PROJECT_VERSION_MINOR LESS "100" AND PROJECT_VERSION_MINOR GREATER "-1")
			math(EXPR ARG_VERSION_CODE "${ARG_VERSION_CODE} + ${PROJECT_VERSION_MINOR} * 10000")
		else()
			message(FATAL_ERROR "PROJECT_VERSION_MINOR exceeding the allowed range of [0, 99]")
		endif()
	endif()
	if(DEFINED PROJECT_VERSION_PATCH AND NOT PROJECT_VERSION_PATCH STREQUAL "")
		if(PROJECT_VERSION_PATCH LESS "100" AND PROJECT_VERSION_PATCH GREATER "-1")
			math(EXPR ARG_VERSION_CODE "${ARG_VERSION_CODE} + ${PROJECT_VERSION_PATCH} * 100")
		else()
			message(FATAL_ERROR "PROJECT_VERSION_PATCH exceeding the allowed range of [0, 99]")
		endif()
	endif()
	if(DEFINED PROJECT_VERSION_TWEAK AND NOT PROJECT_VERSION_TWEAK STREQUAL "")
		if(PROJECT_VERSION_TWEAK LESS "10" AND PROJECT_VERSION_TWEAK GREATER "-1")
			math(EXPR ARG_VERSION_CODE "${ARG_VERSION_CODE} + ${PROJECT_VERSION_TWEAK} * 10")
		else()
			message(FATAL_ERROR "PROJECT_VERSION_TWEAK exceeding the allowed range of [0, 9]")
		endif()
	endif()
	if(CMAKE_ANDROID_ARCH_ABI STREQUAL "arm64-v8a")
		math(EXPR ARG_VERSION_CODE "${ARG_VERSION_CODE} + 1")
	elseif(CMAKE_ANDROID_ARCH_ABI STREQUAL "armeabi-v7a" AND NOT CMAKE_ANDROID_ARM_NEON)
		math(EXPR ARG_VERSION_CODE "${ARG_VERSION_CODE} + 2")
	elseif(CMAKE_ANDROID_ARCH_ABI STREQUAL "armeabi-v7a" AND CMAKE_ANDROID_ARM_NEON)
		math(EXPR ARG_VERSION_CODE "${ARG_VERSION_CODE} + 3")
	elseif(CMAKE_ANDROID_ARCH_ABI STREQUAL "armeabi-v6")
		math(EXPR ARG_VERSION_CODE "${ARG_VERSION_CODE} + 4")
	elseif(CMAKE_ANDROID_ARCH_ABI STREQUAL "armeabi")
		math(EXPR ARG_VERSION_CODE "${ARG_VERSION_CODE} + 5")
	elseif(CMAKE_ANDROID_ARCH_ABI STREQUAL "mips")
		math(EXPR ARG_VERSION_CODE "${ARG_VERSION_CODE} + 6")
	elseif(CMAKE_ANDROID_ARCH_ABI STREQUAL "mips64")
		math(EXPR ARG_VERSION_CODE "${ARG_VERSION_CODE} + 7")
	elseif(CMAKE_ANDROID_ARCH_ABI STREQUAL "x86")
		math(EXPR ARG_VERSION_CODE "${ARG_VERSION_CODE} + 8")
	elseif(CMAKE_ANDROID_ARCH_ABI STREQUAL "x86_64")
		math(EXPR ARG_VERSION_CODE "${ARG_VERSION_CODE} + 9")
	else()
		message(WARNING "Couldn't read valid CMAKE_ANDROID_ARCH_ABI. The VERSION_CODE won't be distinguishable between different abi's")
	endif()

	set(${VAR} ${ARG_VERSION_CODE} PARENT_SCOPE)
endfunction()

# install a target and more (APKs on Android, AppImage on Linux)
function(install_app TARGET)

	install(TARGETS ${TARGET} BUNDLE DESTINATION . LIBRARY DESTINATION ${CMAKE_INSTALL_BINDIR} RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

	if(ANDROID)
		configure_file("${current_dir}/AndroidManifest.xml.in" "${CMAKE_CURRENT_BINARY_DIR}/android_package_src/AndroidManifest.xml" @ONLY)
		gen_version_code(VERSION_CONDE)
		set_target_properties(${TARGET} PROPERTIES QT_ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_BINARY_DIR}/android_package_src")
		set_target_properties(${TARGET} PROPERTIES QT_ANDROID_VERSION_CODE "${VERSION_CONDE}")
		set_target_properties(${TARGET} PROPERTIES QT_ANDROID_VERSION_NAME "${PROJECT_VERSION}")
		message(STATUS "Using Android Version Code '${VERSION_CONDE}' and Version Name '${PROJECT_VERSION}'")
		install(FILES "${CMAKE_CURRENT_BINARY_DIR}/android-build/$<TARGET_NAME:${TARGET}>.apk" DESTINATION .)
	else()
		qt_generate_deploy_qml_app_script(
						TARGET ${TARGET}
						OUTPUT_SCRIPT ${TARGET}_install_app_deploy_script
		)
		install(SCRIPT ${${TARGET}_install_app_deploy_script})
		if(UNIX AND NOT APPLE)
			# TODO: On Unix qt_generate_deploy_qml_app_script is missing some libs. Install every Qt lib so no libs are missing
			install(CODE "
								 file (GLOB so_files LIST_DIRECTORIES false \"${QT6_INSTALL_PREFIX}/${QT6_INSTALL_LIBS}/*.so.*\")
								 message (STATUS \"Qt deployment is missing dependencies on Linux - Installing all Qt libs (resulting in a bigger package than necessary) \")
								 foreach (so_file IN LISTS so_files)
								 file (INSTALL \"\${so_file}\" DESTINATION \"${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}\")
								 endforeach ()
								 message (STATUS \"Qt deployment is missing plugin dependencies on Linux - Installing all Qt plugins (resulting in a bigger package than necessary) \")
								 file (INSTALL \"${QT6_INSTALL_PREFIX}/${QT6_INSTALL_PLUGINS}\" DESTINATION \"${CMAKE_INSTALL_PREFIX}\" FILES_MATCHING PATTERN \"*.so\")
								 ")
		endif()
	endif()
	if(UNIX AND NOT ANDROID AND NOT APPLE)
		include(AppImage)
		install_appimage(${TARGET})
	endif()
endfunction()

# qt_deploy_qml_imports() won't find qml modules outside Qt install dir. Use this function to add custom qml module locations
function(add_qml_import_path TARGET importPath)

	set(qml_import_paths "")
	# Get custom import paths provided during qt_add_qml_module call.
	get_target_property(qml_import_path ${TARGET} QT_QML_IMPORT_PATH)
	if(qml_import_path)
		list(APPEND qml_import_paths ${qml_import_path})
	endif()

	list(APPEND qml_import_paths "${importPath}")
	set_target_properties(${TARGET} PROPERTIES QT_QML_IMPORT_PATH "${qml_import_paths}")
endfunction()

# The MODULE_TARGET has to be installed using install_qml_module(). It won't work otherwise
function(target_link_qml_module TARGET visibility MODULE_TARGET)

	set(qml_import_paths "")
	get_target_property(qml_import_path ${MODULE_TARGET} QT_QML_IMPORT_PATH)
	if(qml_import_path)
		list(APPEND qml_import_paths ${qml_import_path})
	else()
		message(WARNING "The MODULE_TARGET wasn't installed using install_qml_module().")
	endif()

	target_link_libraries(${TARGET} ${visibility} ${MODULE_TARGET})
	add_qml_import_path(${TARGET} ${qml_import_paths})
endfunction()

# Link a Qml module that was created with ecm_add_qml_module
function(target_link_ecm_qml_module TARGET visibility MODULE_PACKAGE)

	find_package(${MODULE_PACKAGE} REQUIRED)
	add_qml_import_path(${TARGET} ${KDE_INSTALL_FULL_QMLDIR})
endfunction()
