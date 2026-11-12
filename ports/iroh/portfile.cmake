vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

if(VCPKG_TARGET_IS_WINDOWS)
    # Rust's MSVC targets always link the release CRT (/MD), also in debug builds.
    set(VCPKG_POLICY_SKIP_CRT_LINKAGE_CHECK enabled)
endif()

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO n0-computer/iroh-c-ffi
    REF "v0.101.0"
    SHA512 da670f3770183cc123d1b5092f7f5c7213fddeff128737375ac891233b8db5f6707873bf317ebb6a73acc936f09784a362261eab197089fec67a3ff2f0f76362
    HEAD_REF main
)

file(WRITE "${SOURCE_PATH}/CMakeLists.txt" [[
cmake_minimum_required(VERSION 3.22)
project(iroh VERSION 0.101.0 LANGUAGES C)

find_package(Corrosion CONFIG REQUIRED)

corrosion_import_crate(
    MANIFEST_PATH Cargo.toml
    CRATES iroh-c-ffi
    CRATE_TYPES staticlib
    LOCKED
)

corrosion_install(
    TARGETS iroh_c_ffi
    ARCHIVE DESTINATION lib
)

# Upstream commits the header produced by its generate_headers binary and its
# CI fails if the two differ, so the checked-in file is the generated header.
install(FILES irohnet.h DESTINATION include)

set(IROH_ARCHIVE_NAME "${CMAKE_STATIC_LIBRARY_PREFIX}iroh_c_ffi${CMAKE_STATIC_LIBRARY_SUFFIX}")
# System libraries the Rust standard library needs, as detected by Corrosion.
set(IROH_NATIVE_LIBS "${Rust_CARGO_TARGET_LINK_NATIVE_LIBS}")

include(CMakePackageConfigHelpers)
configure_package_config_file(
    ${CMAKE_CURRENT_LIST_DIR}/iroh-config.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/iroh-config.cmake
    INSTALL_DESTINATION share/iroh
)
write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/iroh-config-version.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)
install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/iroh-config.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/iroh-config-version.cmake
    DESTINATION share/iroh
)
]])

file(WRITE "${SOURCE_PATH}/iroh-config.cmake.in" [[
@PACKAGE_INIT@

if(NOT TARGET iroh::iroh_c_ffi)
    add_library(iroh::iroh_c_ffi STATIC IMPORTED)
    set_target_properties(iroh::iroh_c_ffi PROPERTIES
        IMPORTED_CONFIGURATIONS RELEASE
        IMPORTED_LOCATION_RELEASE "${PACKAGE_PREFIX_DIR}/lib/@IROH_ARCHIVE_NAME@"
        INTERFACE_INCLUDE_DIRECTORIES "${PACKAGE_PREFIX_DIR}/include"
        INTERFACE_LINK_LIBRARIES "@IROH_NATIVE_LIBS@"
    )
    if(EXISTS "${PACKAGE_PREFIX_DIR}/debug/lib/@IROH_ARCHIVE_NAME@")
        set_property(TARGET iroh::iroh_c_ffi APPEND PROPERTY IMPORTED_CONFIGURATIONS DEBUG)
        set_target_properties(iroh::iroh_c_ffi PROPERTIES
            IMPORTED_LOCATION_DEBUG "${PACKAGE_PREFIX_DIR}/debug/lib/@IROH_ARCHIVE_NAME@"
        )
    endif()
    if(APPLE)
        # From `cargo rustc --crate-type staticlib -- --print native-static-libs`
        foreach(_iroh_framework IN ITEMS
            CoreFoundation CoreWLAN Foundation Security SecurityFoundation SystemConfiguration)
            find_library(_iroh_${_iroh_framework}_FRAMEWORK ${_iroh_framework} REQUIRED)
            set_property(TARGET iroh::iroh_c_ffi APPEND PROPERTY
                INTERFACE_LINK_LIBRARIES "${_iroh_${_iroh_framework}_FRAMEWORK}")
        endforeach()
        set_property(TARGET iroh::iroh_c_ffi APPEND PROPERTY INTERFACE_LINK_LIBRARIES objc iconv)
    endif()
    if(WIN32)
        # From `cargo rustc --crate-type staticlib -- --print native-static-libs`
        set_property(TARGET iroh::iroh_c_ffi APPEND PROPERTY INTERFACE_LINK_LIBRARIES
            legacy_stdio_definitions iphlpapi bcrypt advapi32 kernel32 ntdll userenv ws2_32 dbghelp)
    endif()
endif()

check_required_components(iroh)
]])

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE-MIT" "${SOURCE_PATH}/LICENSE-APACHE")
