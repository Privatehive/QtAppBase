cmake_minimum_required(VERSION 3.21.1)
# Set a default search path for CMake modules
set(CMAKE_MODULE_PATH  "${CMAKE_SOURCE_DIR}/CMake" "${CMAKE_MODULE_PATH}")
include(JSONParser)

# Parse the info.json and write a info.h file
file(READ info.json jsonInfo)
sbeParseJson(info jsonInfo)

project(${info.projectName} VERSION "${info.version.major}.${info.version.minor}.${info.version.patch}" LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Configure a header file to pass some of the CMake settings to the source code.
include_directories("${PROJECT_BINARY_DIR}/src")
file(WRITE "${PROJECT_BINARY_DIR}/src/info.h" "")
foreach(var ${info})
	string(TOUPPER "${var}" UPPER_VAR)
	string(REPLACE "." "_" UPPER_VAR "${UPPER_VAR}")
	if (${${var}} MATCHES "^[0-9]+$")
		file(APPEND "${PROJECT_BINARY_DIR}/src/info.h" "#define ${UPPER_VAR} ${${var}}\n")
	else()
		file(APPEND "${PROJECT_BINARY_DIR}/src/info.h" "#define ${UPPER_VAR} \"${${var}}\"\n")
	endif()
endforeach()

include(FeatureSummary)
feature_summary(WHAT REQUIRED_PACKAGES_NOT_FOUND FATAL_ON_MISSING_REQUIRED_PACKAGES)

find_package(Qt6 REQUIRED COMPONENTS Core Widgets Gui Qml Quick QuickControls2 Linguist)

qt_standard_project_setup()

add_subdirectory(src)

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
