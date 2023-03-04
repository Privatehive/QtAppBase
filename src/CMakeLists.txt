include(GenerateExportHeader)

qt_add_library(${PROJECT_NAME}
							 QtApplicationBase.h
							 QtApplicationBase.cpp
							 AdvancedQmlApplicationEngine.h
							 AdvancedQmlApplicationEngine.cpp
							 LogMessageHandler.h
							 LogMessageHandler.cpp
							 )

generate_export_header(${PROJECT_NAME} EXPORT_FILE_NAME AdvancedQmlApplicationEngine.h)
set_target_properties(${PROJECT_NAME} PROPERTIES PUBLIC_HEADER "materialrallyplugin.h;${CMAKE_CURRENT_BINARY_DIR}/MaterialRallyExport.h")
target_link_libraries(${PROJECT_NAME} PUBLIC Qt6::Core PUBLIC Qt6::Gui Qt6::Quick PUBLIC Qt6::Qml)
target_include_directories(${PROJECT_NAME} PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}> $<INSTALL_INTERFACE:include>)
target_include_directories(${PROJECT_NAME} PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}> $<INSTALL_INTERFACE:include>)

qt_add_executable(${PROJECT_NAME}_test main.cpp)
target_link_libraries(${PROJECT_NAME}_test PRIVATE ${PROJECT_NAME})

install(TARGETS ${PROJECT_NAME} EXPORT ${PROJECT_NAME}-Targets BUNDLE DESTINATION . RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
