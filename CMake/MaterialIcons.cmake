find_package(Qt6 REQUIRED COMPONENTS Core)

set(MAT_ICONS_BASE_URL "https://fonts.gstatic.com/s/i/short-term/release/materialsymbolsoutlined/@icon_name@/default/48px.svg")

# create_material_icon_theme(THEME_NAME <icon_theme_name> DIR <output_dir> ICONS <icon_name>... [FILES <generated_files_of_theme>])
function(create_material_icon_theme)
	set(options)
	set(oneValueArgs THEME_NAME DIR FILES)
	set(multiValueArgs ICONS)
	cmake_parse_arguments(MAT_ICONS_CP "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

	set(MAT_ICONS_BASE_DIR "${MAT_ICONS_CP_DIR}")
	set(MAT_ICONS_THEME_DIR "${MAT_ICONS_BASE_DIR}/${MAT_ICONS_CP_THEME_NAME}")
	set(MAT_ICONS_ICON_DIR "${MAT_ICONS_THEME_DIR}/48x48/")

	file(MAKE_DIRECTORY "${MAT_ICONS_ICON_DIR}")

	file(WRITE "${MAT_ICONS_THEME_DIR}/index.theme" "[Icon Theme]\nName=${MAT_ICONS_CP_THEME_NAME}\nDirectories=48x48\n\n[48x48]\nSize=48\nType=Fixed\n")

	set(MAT_ICONS_FILES "${MAT_ICONS_THEME_DIR}/index.theme")
	foreach(MAT_ICONS_ICON IN LISTS MAT_ICONS_CP_ICONS)
		set(MAT_ICONS_FILE_NAME "${MAT_ICONS_ICON_DIR}/${MAT_ICONS_ICON}.svg")
		if(NOT EXISTS "${MAT_ICONS_FILE_NAME}")
			string(REPLACE "@icon_name@" "${MAT_ICONS_ICON}" MAT_ICONS_ICON_URL "${MAT_ICONS_BASE_URL}")
			message(STATUS "Downloading icon '${MAT_ICONS_ICON}'")
			file(DOWNLOAD "${MAT_ICONS_ICON_URL}" "${MAT_ICONS_FILE_NAME}" SHOW_PROGRESS STATUS MAT_ICONS_DOWNL_STATUS)
			list(GET MAT_ICONS_DOWNL_STATUS 0 MAT_ICONS_DOWNL_ERROR)
			list(GET MAT_ICONS_DOWNL_STATUS 1 MAT_ICONS_DOWNL_ERROR_MSG)
			if(MAT_ICONS_DOWNL_ERROR)
				file(REMOVE "${MAT_ICONS_FILE_NAME}")
				message(FATAL_ERROR "Could not download icon '${MAT_ICONS_ICON}': ${MAT_ICONS_DOWNL_ERROR_MSG}")
			endif()
		endif()
		list(APPEND MAT_ICONS_FILES "${MAT_ICONS_FILE_NAME}")
	endforeach()

	set(${MAT_ICONS_CP_FILES} ${MAT_ICONS_FILES} PARENT_SCOPE)
endfunction()

# add_material_icon_theme_resource(<target> THEME_NAME <icon_theme_name> DIR <output_dir> ICONS <icon_name>...)
function(add_material_icon_theme_resource TARGET)
	set(options)
	set(oneValueArgs THEME_NAME)
	set(multiValueArgs ICONS)
	cmake_parse_arguments(MAT_ICONS_CPA "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

	create_material_icon_theme(THEME_NAME "${MAT_ICONS_CPA_THEME_NAME}" DIR "${PROJECT_BINARY_DIR}/.icons" ICONS "${MAT_ICONS_CPA_ICONS}" FILES MAT_ICONS_FILES)

	qt_add_resources(${TARGET} "${MAT_ICONS_CPA_THEME_NAME}_icon_theme" BASE "${PROJECT_BINARY_DIR}/.icons" PREFIX "/icons" FILES "${MAT_ICONS_FILES}")
endfunction()
