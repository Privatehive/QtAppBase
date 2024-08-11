include(GenerateExportHeader)

set(FEATURE_TEST_APP OFF CACHE BOOL "Build a test app")
set(FEATURE_SECRETS_MANAGER OFF CACHE BOOL "Enables access to the OS secret manager, or a generic one if the OS doesn't provide one")
set(FEATURE_QML OFF CACHE BOOL "Expose features to Qml")

find_package(Qt6 REQUIRED COMPONENTS Core)

qt_add_library(QtAppBase
        LogMessageHandler.h
        QtApplicationBase.h
        LogMessageHandler.cpp
)

generate_export_header(QtAppBase EXPORT_FILE_NAME QtApplicationBaseExport.h)

target_mark_public_header(QtAppBase
        LogMessageHandler.h
        QtApplicationBase.h
        ${CMAKE_CURRENT_BINARY_DIR}/QtApplicationBaseExport.h
)

target_link_libraries(QtAppBase PUBLIC Qt6::Core)
target_include_directories(QtAppBase PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}> $<INSTALL_INTERFACE:include>)
target_include_directories(QtAppBase PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}> $<INSTALL_INTERFACE:include>)

if (FEATURE_QML)
    find_package(Qt6 REQUIRED COMPONENTS Quick Qml)
    set(QT_QML_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")
    target_sources(QtAppBase
            PRIVATE
            AdvancedQmlApplicationEngine.h
            AdvancedQmlApplicationEngine.cpp
    )

    target_mark_public_header(QtAppBase
            AdvancedQmlApplicationEngine.h
    )

    target_link_libraries(QtAppBase PUBLIC Qt6::Quick PUBLIC Qt6::Qml)
endif ()

if (FEATURE_SECRETS_MANAGER)
    find_package(Qt6Keychain REQUIRED)
    add_dependency(QtAppBase Qt6Keychain)
    target_sources(QtAppBase PRIVATE SecretsManager.h SecretsManager.cpp)
    target_mark_public_header(QtAppBase SecretsManager.h)
    target_link_libraries(QtAppBase PUBLIC Qt6Keychain::Qt6Keychain)
    if (UNIX)
        message(STATUS "Enabled Secrets Manager for Linux")
        target_sources(QtAppBase PRIVATE linux/SecretsManagerImpl.cpp)
        target_include_directories(QtAppBase PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/linux> $<INSTALL_INTERFACE:include>)
    elseif (WIN32)
        message(STATUS "Enabled Secrets Manager for Windows")
        target_sources(QtAppBase PRIVATE windows/SecretsManagerImpl.cpp)
        target_include_directories(QtAppBase PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/windows> $<INSTALL_INTERFACE:include>)
    elseif (ANDROID)
        message(STATUS "Enabled Secrets Manager for Android")
        target_sources(QtAppBase PRIVATE android/SecretsManagerImpl.cpp)
        target_include_directories(QtAppBase PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/android> $<INSTALL_INTERFACE:include>)
    endif ()
    if (FEATURE_QML)
        qt_add_qml_module(QtAppBaseQml
                URI
                QtAppBase

                SOURCES
                Secret.h
                Secret.cpp
        )

        generate_export_header(QtAppBaseQml EXPORT_FILE_NAME QtApplicationBaseQmlExport.h)

        target_mark_public_header(QtAppBase
                Secret.h
                ${CMAKE_CURRENT_BINARY_DIR}/QtApplicationBaseQmlExport.h
        )
        target_link_libraries(QtAppBaseQml PUBLIC QtAppBase)
        install_qml_module(QtAppBaseQml)
    endif ()
endif ()

install_qt_library(QtAppBase)

if (FEATURE_TEST_APP AND FEATURE_QML)

    find_package(Qt6 REQUIRED COMPONENTS Gui QuickControls2)
    qt_add_executable(QtAppBaseTestApp mainQml.cpp)
    target_link_libraries(QtAppBaseTestApp PRIVATE QtAppBase PRIVATE QtAppBaseQml PRIVATE Qt6::Quick PRIVATE Qt6::QuickControls2 PRIVATE Qt6::Qml PRIVATE Qt6::Gui)

    qt_add_qml_module(QtAppBaseTestApp
            URI
            QtAppBaseTest

            QML_FILES
            QtAppBaseTest/main.qml
    )

    install_app(QtAppBaseTestApp)
endif ()
