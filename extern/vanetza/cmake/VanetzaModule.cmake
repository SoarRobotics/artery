option(VANETZA_BUILD_STATIC "Build static libraries of Vanetza" OFF)
option(VANETZA_BUILD_SHARED "Build shared libraries of Vanetza" ON)
option(VANETZA_PREFER_STATIC "Prefer static over shared libraries where possible" OFF)

if(VANETZA_PREFER_STATIC AND NOT VANETZA_BUILD_STATIC)
    message(WARNING "VANETZA_PREFER_STATIC is set without VANETZA_BUILD_STATIC. Shared libraries will be used.")
endif()

macro(vanetza_module NAME)
    set(_sources ${ARGN})
    if(VANETZA_BUILD_SHARED)
        add_library(${NAME}_shared SHARED ${_sources})
        set_property(TARGET ${NAME}_shared PROPERTY OUTPUT_NAME vanetza_${NAME})
        target_include_directories(${NAME}_shared PUBLIC ${VANETZA_MODULE_INCLUDE_DIRECTORIES})
        install(TARGETS ${NAME}_shared EXPORT ${PROJECT_NAME} DESTINATION lib)
    endif(VANETZA_BUILD_SHARED)
    if(VANETZA_BUILD_STATIC)
        add_library(${NAME}_static STATIC ${_sources})
        set_property(TARGET ${NAME}_static PROPERTY OUTPUT_NAME vanetza_${NAME})
        target_include_directories(${NAME}_static PUBLIC ${VANETZA_MODULE_INCLUDE_DIRECTORIES})
        install(TARGETS ${NAME}_static EXPORT ${PROJECT_NAME} DESTINATION lib)
    endif(VANETZA_BUILD_STATIC)

    if(VANETZA_BUILD_STATIC AND (VANETZA_PREFER_STATIC OR NOT VANETZA_BUILD_SHARED))
        add_library(${NAME} ALIAS ${NAME}_static)
    elseif(VANETZA_BUILD_SHARED)
        add_library(${NAME} ALIAS ${NAME}_shared)
    else()
        message(FATAL_ERROR "Neither SHARED nor STATIC libraries are built. Check VANETZA_BUILD_STATIC and VANETZA_BUILD_SHARED settings.")
    endif()
endmacro()

macro(vanetza_module_dependencies NAME)
    set(_deps ${ARGN})
    foreach(_dep ${_deps})
        if(TARGET ${NAME}_shared)
            add_dependencies(${NAME}_shared ${_dep})
        endif()
        if(TARGET ${NAME}_static)
            add_dependencies(${NAME}_static ${_dep})
        endif()
    endforeach()
endmacro()

macro(vanetza_module_link_libraries NAME)
    if(TARGET ${NAME}_shared)
        target_link_libraries(${NAME}_shared ${ARGN})
    endif()
    if(TARGET ${NAME}_static)
        target_link_libraries(${NAME}_static ${ARGN})
    endif()
endmacro()

macro(vanetza_intermodule_dependencies NAME)
    set(_modules ${ARGN})
    foreach(_module ${_modules})
        if(TARGET ${NAME}_shared)
            target_link_libraries(${NAME}_shared ${_module}_shared)
        endif()
        if(TARGET ${NAME}_static)
            target_link_libraries(${NAME}_static ${_module}_static)
        endif()
    endforeach()
endmacro()

macro(vanetza_module_property NAME)
    if(TARGET ${NAME}_shared)
        set_property(TARGET ${NAME}_shared APPEND PROPERTY ${ARGN})
    endif()
    if(TARGET ${NAME}_static)
        set_property(TARGET ${NAME}_static APPEND PROPERTY ${ARGN})
    endif()
endmacro()

macro(vanetza_export_modules)
    string(TOLOWER ${PROJECT_NAME} _project_name_lower)
    export(EXPORT ${PROJECT_NAME} NAMESPACE Vanetza:: FILE ${_project_name_lower}-targets.cmake)
    file(WRITE ${PROJECT_BINARY_DIR}/vanetza-config.cmake
        "include(\"${PROJECT_BINARY_DIR}/${_project_name_lower}-targets.cmake\")")
    export(PACKAGE ${PROJECT_NAME})
endmacro()
