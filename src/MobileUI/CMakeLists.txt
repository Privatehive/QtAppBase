find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml)

set(CORE_SOURCES MobileUI.h MobileUI.cpp)

# OS specific sources & dependencies
if (ANDROID)
    set(PLATFORM_SOURCES MobileUI_android_qt6.cpp)
elseif (IOS)
    set(PLATFORM_SOURCES MobileUI_ios.mm)
    set(PLATFORM_LIBRARIES "-framework UIKit")
else ()
    set(PLATFORM_SOURCES MobileUI_dummy.cpp)
endif ()

################################################################################

qt_add_library(MobileUI ${CORE_SOURCES} ${PLATFORM_SOURCES})

target_link_libraries(MobileUI PRIVATE Qt::Core PRIVATE Qt::Gui PRIVATE Qt::Qml PRIVATE ${PLATFORM_LIBRARIES})
target_mark_public_header(MobileUI MobileUI.h MobileUI)

install_qt_library(MobileUI)
