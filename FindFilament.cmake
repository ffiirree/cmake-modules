find_path(
    Filament_INCLUDE_DIR
    NAMES filament/Engine.h
    PATH_SUFFIXES include
)

if(Filament_INCLUDE_DIR)
    get_filename_component(Filament_ROOT_DIR "${Filament_INCLUDE_DIR}" DIRECTORY)
endif()

if(NOT Filament_FIND_COMPONENTS)
    list(APPEND
        Filament_FIND_COMPONENTS
        filament
        backend
        bluegl # OpenGL bindings for macOS, Linux and Windows
        bluevk # Vulkan bindings for macOS, Linux, Windows and Android
        camutils # Camera manipulation utilities
        filabridge # Library shared by the Filament engine and host tools
        filaflat # Serialization/deserialization library used for materials
        filamat # Material generation library
        filameshio # Tiny filamesh parsing library (see also tools/filamesh)
        geometry # Mesh-related utilities
        gltfio_core
        gltfio # Loader for glTF 2.0
        ibl # IBL generation tools
        image # Image filtering and simple transforms
        imageio # Image file reading / writing, only intended for internal use
        matdbg # DebugServer for inspecting shaders at run-time (debug builds only)
        math # Math library
        mathio # Math types support for output streams
        utils # Utility library (threads, memory, data structures, etc.)
        viewer # glTF viewer library (requires gltfio)
        zstd
        smol-v
    )
endif()

foreach(COMPONENT ${Filament_FIND_COMPONENTS})
    if(MSVC)
        find_library(
            Filament_${COMPONENT}_LIBRARY_RELEASE
            NAMES "${COMPONENT}" "lib${COMPONENT}"
            PATHS ${Filament_ROOT_DIR}
            PATH_SUFFIXES lib/x86_64/md
            NO_DEFAULT_PATH
        )

        find_library(
            Filament_${COMPONENT}_LIBRARY_DEBUG
            NAMES "${COMPONENT}" "lib${COMPONENT}"
            PATHS ${Filament_ROOT_DIR}
            PATH_SUFFIXES lib/x86_64/mdd
            NO_DEFAULT_PATH
        )

        if(Filament_${COMPONENT}_LIBRARY_RELEASE OR Filament_${COMPONENT}_LIBRARY_DEBUG)
            if(NOT TARGET filament::${COMPONENT})
                add_library(filament::${COMPONENT} STATIC IMPORTED)
                set_target_properties(filament::${COMPONENT}
                    PROPERTIES
                    INTERFACE_INCLUDE_DIRECTORIES "${Filament_INCLUDE_DIR}"

                    IMPORTED_LOCATION_RELEASE "${Filament_${COMPONENT}_LIBRARY_RELEASE}"
                    IMPORTED_LOCATION_RELWITHDEBINFO "${Filament_${COMPONENT}_LIBRARY_RELEASE}"
                    IMPORTED_LOCATION_MINSIZEREL "${Filament_${COMPONENT}_LIBRARY_RELEASE}"
                    IMPORTED_LOCATION_DEBUG "${Filament_${COMPONENT}_LIBRARY_DEBUG}"
                )

                set(Filament_${COMPONENT}_FOUND TRUE)
            endif()
        endif()
    else()
        find_library(
            Filament_${COMPONENT}_LIBRARY
            NAMES "${COMPONENT}" "lib${COMPONENT}"
            PATHS ${Filament_ROOT_DIR}
            PATH_SUFFIXES lib/x86_64
            NO_DEFAULT_PATH
        )

        
        if(Filament_${COMPONENT}_LIBRARY)
            if(NOT TARGET filament::${COMPONENT})
                add_library(filament::${COMPONENT} STATIC IMPORTED)
                set_target_properties(filament::${COMPONENT}
                    PROPERTIES
                    INTERFACE_INCLUDE_DIRECTORIES "${Filament_INCLUDE_DIR}"

                    IMPORTED_LOCATION "${Filament_${COMPONENT}_LIBRARY}"
                )

                set(Filament_${COMPONENT}_FOUND TRUE)
            endif()
        endif()
    endif()
endforeach()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(
    Filament
    REQUIRED_VARS Filament_ROOT_DIR Filament_INCLUDE_DIR
    HANDLE_COMPONENTS
)