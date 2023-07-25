include(GenerateExportHeader)


set(INSTALL_APPS OFF CACHE BOOL "Install test apps")
find_package(Qt6 REQUIRED COMPONENTS Core Gui Widgets Quick Qml)

# lib
qt_add_library(QtAppBase
							 QtApplicationBase.h
							 AdvancedQmlApplicationEngine.h
							 AdvancedQmlApplicationEngine.cpp
							 LogMessageHandler.h
							 LogMessageHandler.cpp
							 )

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

# qml test app
qt_add_executable(QtAppBase_test_qml mainQml.cpp)
target_link_libraries(QtAppBase_test_qml PRIVATE QtAppBase)

qt_add_qml_module(QtAppBase_test_qml URI Application VERSION 1.0 RESOURCE_PREFIX / QML_FILES
									qml/main.qml
									)

install_app(QtAppBase_test_qml)
