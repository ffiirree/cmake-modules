# FindFilament.cmake
# Find Filament rendering engine
#
# This module defines:
#  Filament_FOUND - If false, do not try to use Filament
#  Filament_INCLUDE_DIRS - Include directories for Filament
#  Filament_LIBRARIES - Libraries to link to

set(Filament_ROOT "" CACHE PATH "Root directory of Filament SDK")

# Check environment variable if not set
if(NOT Filament_ROOT AND DEFINED ENV{FILAMENT_DIR})
  set(Filament_ROOT "$ENV{FILAMENT_DIR}")
endif()

# Find include directory
find_path(Filament_INCLUDE_DIR
        NAMES filament/Engine.h
        PATHS
        ${Filament_ROOT}
        ${Filament_ROOT}/include
        PATH_SUFFIXES include
)

# Set library search paths - try multiple possible locations
set(_filament_lib_paths
        ${Filament_ROOT}/lib
        ${Filament_ROOT}/lib/x86_64
)

# Define all Filament libraries to find (in link order)
# 注意：gltfio 是薄包装层，实际实现（AssetLoader/FilamentAsset等）在 gltfio_core 中
# 注意：meshoptimizer, mikktspace, stb 等已嵌入 geometry/libmeshoptimizer.a 等库中，不要单独链接
set(FILAMENT_LIBRARIES_NAMES
        shaders            # 预编译着色器数据包 SHADERS_PACKAGE（filamat 依赖）
        ibl
        image
        filament
        filabridge
        filaflat
        smol-v
        filamat
        backend
        gltfio
        gltfio_core        # GLTF 核心实现（AssetLoader、FilamentAsset 等）
        utils
        bluegl
        bluevk
        filameshio         # 网格加载器（GLTF 依赖）
        ktxreader          # KTX 纹理读取器（GLTF 依赖）
        dracodec           # Draco 解压缩（GLTF 可选依赖）
        geometry           # 几何工具（包含 meshoptimizer/mikktspace/stb）
        basis_transcoder   # BasisU 纹理解码（imageio 依赖）
        uberarchive        # Ubershader 材质档案（gltfio 依赖）
        uberzlib           # UberZ 压缩库（uberarchive 依赖）
        matp               # 材质处理（uberarchive 依赖）
)

# Find all libraries using loop
foreach(lib_name ${FILAMENT_LIBRARIES_NAMES})
  if(NOT WIN32)
    # On non-Windows platforms (Linux, macOS), find_library() automatically adds the 'lib' prefix
    # e.g., NAMES ibl => searches for libibl.so, libibl.a on Linux
    find_library(Filament_${lib_name}_LIBRARY
      NAMES ${lib_name}
      PATHS ${_filament_lib_paths})
  else()
    # On Windows, library names may or may not have 'lib' prefix
    # e.g., ibl.lib or libibl.lib
    find_library(Filament_${lib_name}_LIBRARY
      NAMES ${lib_name} lib${lib_name}
      PATHS ${_filament_lib_paths})
  endif()
  list(APPEND _required_vars Filament_${lib_name}_LIBRARY)
endforeach()

# Set results
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Filament
        REQUIRED_VARS
        Filament_INCLUDE_DIR
        ${_required_vars}
)

if(Filament_FOUND)
  set(Filament_INCLUDE_DIRS ${Filament_INCLUDE_DIR})

  # Build library list in correct link order
  set(Filament_LIBRARIES "")
  foreach(lib_name ${FILAMENT_LIBRARIES_NAMES})
    list(APPEND Filament_LIBRARIES ${Filament_${lib_name}_LIBRARY})
  endforeach()

  # Create imported targets for each library
  foreach(lib_name ${FILAMENT_LIBRARIES_NAMES})
    if(NOT TARGET Filament::${lib_name})
      add_library(Filament::${lib_name} STATIC IMPORTED)
      set_target_properties(Filament::${lib_name} PROPERTIES
              IMPORTED_LOCATION "${Filament_${lib_name}_LIBRARY}"
      )
      # filament core library needs include directories
      if(lib_name STREQUAL "filament")
        set_target_properties(Filament::${lib_name} PROPERTIES
                INTERFACE_INCLUDE_DIRECTORIES "${Filament_INCLUDE_DIR}"
        )
      endif()
    endif()
  endforeach()
else()
  message(WARNING "Filament not found. Filament features will be disabled.")
endif()

# Mark all library variables as advanced
mark_as_advanced(Filament_INCLUDE_DIR)
foreach(lib_name ${FILAMENT_LIBRARIES_NAMES})
  mark_as_advanced(Filament_${lib_name}_LIBRARY)
endforeach()
