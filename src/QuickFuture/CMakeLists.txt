find_package(Qt6 REQUIRED COMPONENTS Core Qml)

#set(quickfutureqmlplugin_outputDir "${CMAKE_CURRENT_BINARY_DIR}/QuickFutureBuildDir/QuickFuture")

#add_library(quickfutureqmlplugin SHARED qffuture.h qfvariantwrapper.h quickfuture.h QuickFuture qffuture.cpp)

#target_include_directories(quickfutureqmlplugin INTERFACE
#        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
#        $<INSTALL_INTERFACE:include>)

#add_custom_command(TARGET quickfutureqmlplugin POST_BUILD
#        COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_CURRENT_SOURCE_DIR}/qmldir" "${quickfutureqmlplugin_outputDir}/qmldir"
#        COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_CURRENT_SOURCE_DIR}/quickfuture.qmltypes" "${quickfutureqmlplugin_outputDir}/quickfuture.qmltypes")

#target_link_libraries(quickfutureqmlplugin PRIVATE Qt6::Core Qt6::Qml)


qt_add_qml_module(
        QuickFuture

        VERSION 1.0

        NO_PLUGIN

        URI
        QuickFuture

        SOURCES
        qffuture.h
        qffuture.cpp
        qfvariantwrapper.h
        quickfuture.h
        QuickFuture
)

target_mark_public_header(QuickFuture quickfuture.h qffuture.h qfvariantwrapper.h QuickFuture)

install_qml_module(QuickFuture)
