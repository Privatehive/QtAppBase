include(GenerateExportHeader)


set(INSTALL_APPS OFF CACHE BOOL "Install test apps")
set(FEATURE_SECRETS_MANAGER ON CACHE BOOL "Enables access to the OS secret manager, or a generic one if the OS doesn't provide one")

find_package(Qt6 REQUIRED COMPONENTS Core Gui Widgets Quick Qml)

# lib
qt_add_library(QtAppBase
							 QtApplicationBase.h
							 AdvancedQmlApplicationEngine.h
							 AdvancedQmlApplicationEngine.cpp
							 LogMessageHandler.h
							 LogMessageHandler.cpp
							 )

if(FEATURE_SECRETS_MANAGER)
	find_package(Qt6Keychain REQUIRED)
	target_sources(QtAppBase PRIVATE SecretsManager.h SecretsManager.cpp)
	if(LINUX)
		find_package(Qt6 REQUIRED COMPONENTS DBus)
		message(STATUS "Enabled Secrets Manager for Linux")
		target_sources(QtAppBase PRIVATE linux/SecretsManagerImpl.cpp)
		target_include_directories(QtAppBase PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/linux> $<INSTALL_INTERFACE:include>)
	elseif(WIN32)
		message(STATUS "Enabled Secrets Manager for Windows")
		target_include_directories(QtAppBase PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/windows> $<INSTALL_INTERFACE:include>)
	elseif(ANDROID)
		message(STATUS "Enabled Secrets Manager for Android")
		target_sources(QtAppBase PRIVATE android/SecretsManagerImpl.cpp)
		target_include_directories(QtAppBase PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/android> $<INSTALL_INTERFACE:include>)
	endif()
	target_link_libraries(QtAppBase PUBLIC qt6keychain)
endif()

generate_export_header(QtAppBase EXPORT_FILE_NAME QtApplicationBaseExport.h)
set_target_properties(QtAppBase PROPERTIES PUBLIC_HEADER "LogMessageHandler.h;QtApplicationBase.h;AdvancedQmlApplicationEngine.h;${CMAKE_CURRENT_BINARY_DIR}/QtApplicationBaseExport.h")
target_link_libraries(QtAppBase PUBLIC Qt6::Core PUBLIC Qt6::Gui Qt6::Quick PUBLIC Qt6::Qml)
target_include_directories(QtAppBase PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}> $<INSTALL_INTERFACE:include>)
target_include_directories(QtAppBase PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}> $<INSTALL_INTERFACE:include>)

install(TARGETS QtAppBase EXPORT QtAppBase-Targets BUNDLE DESTINATION . RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

install(EXPORT QtAppBase-Targets
				DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/QtAppBase"
				)

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/QtAppBaseConfig.cmake.in ${CMAKE_CURRENT_BINARY_DIR}/QtAppBaseConfig.cmake COPYONLY)
export(
				EXPORT QtAppBase-Targets
				FILE "${CMAKE_CURRENT_BINARY_DIR}/QtAppBase-Targets.cmake"
)

install(
				FILES ${CMAKE_CURRENT_BINARY_DIR}/QtAppBaseConfig.cmake
				DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/QtAppBase"
)


# widgets test app
if(OFF)
	qt_add_executable(QtAppBase_test_widgets mainWidgets.cpp)
	target_link_libraries(QtAppBase_test_widgets PRIVATE QtAppBase PRIVATE Qt6::Widgets)


	install(TARGETS QtAppBase_test_widgets EXPORT QtAppBase_test_widgets-Targets BUNDLE DESTINATION . LIBRARY DESTINATION ${CMAKE_INSTALL_BINDIR} RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

	if(ANDROID)
		qt_android_generate_deployment_settings(QtAppBase_test_widgets)
		qt_android_add_apk_target(QtAppBase_test_widgets)
	else()
		qt_generate_deploy_app_script(
						TARGET QtAppBase_test_widgets
						OUTPUT_SCRIPT QtAppBase_test_widgets_deploy
		)
		install(SCRIPT ${QtAppBase_test_widgets_deploy})
	endif()
endif()

set(QT_QML_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")

if(FEATURE_SECRETS_MANAGER)
	# qml test app
	qt_add_executable(QtAppBase_test_qml mainQml.cpp)
	target_link_libraries(QtAppBase_test_qml PRIVATE QtAppBase)

	qt_add_qml_module(QtAppBase_test_qml
										URI QtAppBase

										QML_FILES
										QtAppBase/main.qml

										SOURCES
										Secret.h
										Secret.cpp
										)

	install_app(QtAppBase_test_qml)
endif()
