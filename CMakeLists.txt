cmake_minimum_required(VERSION 3.10)
project(pilot-link 
        VERSION 0.13.0
        DESCRIPTION "Suite of tools for moving data between Palm devices and computers"
        LANGUAGES C)

# Set output directories
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# Include system checks
include(CheckIncludeFiles)
include(CheckTypeSize)
include(CheckStructHasMember)

# Check for required headers
check_include_files(sys/socket.h HAVE_SYS_SOCKET_H)
check_include_files(sys/types.h HAVE_SYS_TYPES_H)
check_include_files(inttypes.h HAVE_INTTYPES_H)
check_include_files(stdint.h HAVE_STDINT_H)
check_include_files(sys/time.h HAVE_SYS_TIME_H)

# Define signal handler return type
add_definitions(
    -DRETSIGTYPE=void
)

# Configure config.h
set(HOST_OS ${CMAKE_HOST_SYSTEM})
set(NULL_DEVICE "/dev/null")

# Check for socklen_t
include(CheckSymbolExists)
check_symbol_exists(socklen_t "sys/socket.h" HAVE_SOCKLEN_T)

configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/config.h.in
    ${CMAKE_CURRENT_BINARY_DIR}/config.h
    @ONLY
)

# Make config.h available to all targets
include_directories(${CMAKE_BINARY_DIR})

# Options
option(BUILD_SHARED_LIBS "Build shared libraries" ON)
option(ENABLE_USB "Enable USB support" ON)
option(ENABLE_BLUETOOTH "Enable Bluetooth support" OFF)
option(ENABLE_THREADS "Enable thread support" ON)

# Find required packages
find_package(Threads)

# Handle Bluetooth dependencies
set(HAVE_BLUEZ OFF)
if(ENABLE_BLUETOOTH)
    find_package(PkgConfig)
    pkg_check_modules(BLUEZ bluez)
    if(BLUEZ_FOUND)
        set(HAVE_BLUEZ ON)
    else()
        message(STATUS "Bluetooth support disabled - bluez not found")
        set(ENABLE_BLUETOOTH OFF)
    endif()
endif()

# Configure header with version info
configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/include/pi-version.h.in
    ${CMAKE_CURRENT_BINARY_DIR}/include/pi-version.h
    @ONLY
)

# Add subdirectories
add_subdirectory(libpisock)
add_subdirectory(src)

# Installation settings
include(GNUInstallDirs)
install(DIRECTORY include/
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/pilot-link
        FILES_MATCHING PATTERN "*.h"
        PATTERN "pi-version.h.in" EXCLUDE)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/include/pi-version.h
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/pilot-link)
