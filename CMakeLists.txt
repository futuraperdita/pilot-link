cmake_minimum_required(VERSION 3.10)
project(pilot-link 
        VERSION 0.13.0
        DESCRIPTION "Suite of tools for moving data between Palm devices and computers"
        LANGUAGES C)

# Add cmake modules directory to module path
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules")

# Include GNUInstallDirs for installation paths
include(GNUInstallDirs)

# Extract version components for pi-version.h
string(REGEX MATCH "^([0-9]+)\\.([0-9]+)\\.([0-9]+)" _ ${PROJECT_VERSION})
set(PILOT_LINK_VERS ${CMAKE_MATCH_1})
set(PILOT_LINK_MAJOR ${CMAKE_MATCH_2})
set(PILOT_LINK_MINOR ${CMAKE_MATCH_3})
set(PILOT_LINK_PATCH "")

# Set output directories
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# Include system checks
include(CheckIncludeFiles)
include(CheckTypeSize)
include(CheckStructHasMember)
include(CheckSymbolExists)
include(CheckFunctionExists)
include(CheckLibraryExists)

# Check for required headers
check_include_files(sys/socket.h HAVE_SYS_SOCKET_H)
check_include_files(sys/types.h HAVE_SYS_TYPES_H)
check_include_files(inttypes.h HAVE_INTTYPES_H)
check_include_files(stdint.h HAVE_STDINT_H)
check_include_files(sys/time.h HAVE_SYS_TIME_H)
check_include_files(sys/ioctl.h HAVE_SYS_IOCTL_H)
check_include_files(sys/select.h HAVE_SYS_SELECT_H)
check_include_files(termios.h HAVE_TERMIOS_H)
check_include_files(unistd.h HAVE_UNISTD_H)
check_include_files(dirent.h HAVE_DIRENT_H)
check_include_files(string.h HAVE_STRING_H)

# Check for required functions
check_function_exists(cfmakeraw HAVE_CFMAKERAW)
check_function_exists(cfsetspeed HAVE_CFSETSPEED)
check_function_exists(strdup HAVE_STRDUP)
check_function_exists(strerror HAVE_STRERROR)
check_function_exists(gettimeofday HAVE_GETTIMEOFDAY)

# Check for required types and their sizes
check_type_size("long long" HAVE_LONG_LONG)
check_type_size("unsigned long long" HAVE_UNSIGNED_LONG_LONG)
check_type_size("size_t" HAVE_SIZE_T)
check_type_size("ssize_t" HAVE_SSIZE_T)

# Define signal handler return type
add_definitions(
    -DRETSIGTYPE=void
)

# Configure config.h
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(HOST_OS "linux")
    set(NULL_DEVICE "/dev/null")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    set(HOST_OS "darwin")
    set(NULL_DEVICE "/dev/null")
elseif(CMAKE_SYSTEM_NAME STREQUAL "FreeBSD")
    set(HOST_OS "freebsd")
    set(NULL_DEVICE "/dev/null")
else()
    set(HOST_OS ${CMAKE_HOST_SYSTEM})
    set(NULL_DEVICE "/dev/null")
endif()

# Check for socklen_t
check_symbol_exists(socklen_t "sys/socket.h" HAVE_SOCKLEN_T)

# Check for endianness
include(TestBigEndian)
test_big_endian(IS_BIG_ENDIAN)
if(IS_BIG_ENDIAN)
    set(WORDS_BIGENDIAN 1)
endif()

configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/config.h.in
    ${CMAKE_CURRENT_BINARY_DIR}/config.h
    @ONLY
)

# Make config.h available to all targets
include_directories(${CMAKE_BINARY_DIR})

# Options
option(BUILD_SHARED_LIBS "Build shared libraries" ON)
option(BUILD_STATIC_LIBS "Build static libraries" OFF)
option(ENABLE_USB "Enable USB support" ON)
option(ENABLE_BLUETOOTH "Enable Bluetooth support" OFF)
option(ENABLE_THREADS "Enable thread support" ON)
option(ENABLE_READLINE "Enable readline support" ON)
option(BUILD_DOCUMENTATION "Build documentation using Doxygen" OFF)

# Language bindings
option(ENABLE_PYTHON "Build Python bindings" OFF)
option(ENABLE_JAVA "Build Java bindings" OFF)
option(ENABLE_TCL "Build Tcl bindings" OFF)
option(ENABLE_PERL "Build Perl bindings" OFF)

# Documentation
if(BUILD_DOCUMENTATION)
    find_package(Doxygen)
    if(DOXYGEN_FOUND)
        configure_file(
            ${CMAKE_CURRENT_SOURCE_DIR}/doc/doxygen.cfg.in
            ${CMAKE_CURRENT_BINARY_DIR}/doc/doxygen.cfg
            @ONLY
        )
        add_custom_target(doc ALL
            COMMAND ${DOXYGEN_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/doc/doxygen.cfg
            WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
            COMMENT "Generating API documentation with Doxygen"
            VERBATIM
        )
        if(IS_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/doc/html)
            install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/doc/html/
                    DESTINATION ${CMAKE_INSTALL_DOCDIR}
                    COMPONENT documentation)
        endif()
    else()
        message(STATUS "Documentation disabled - Doxygen not found")
        set(BUILD_DOCUMENTATION OFF)
    endif()
endif()

# Find required packages
find_package(Threads REQUIRED)

# Find libusb if USB support is enabled
if(ENABLE_USB)
    find_package(LibUSB)
    if(NOT LibUSB_FOUND)
        message(STATUS "USB support disabled - libusb not found")
        set(ENABLE_USB OFF)
    endif()
endif()

# Optional packages based on enabled features
if(ENABLE_READLINE)
    find_package(Readline)
    if(NOT Readline_FOUND)
        message(STATUS "Readline support disabled - library not found")
        set(ENABLE_READLINE OFF)
    endif()
endif()

# Language binding dependencies
if(ENABLE_PYTHON)
    find_package(Python3 COMPONENTS Interpreter Development)
    if(NOT Python3_FOUND)
        message(STATUS "Python bindings disabled - Python3 not found")
        set(ENABLE_PYTHON OFF)
    endif()
endif()

if(ENABLE_JAVA)
    find_package(Java COMPONENTS Development)
    find_package(JNI)
    if(NOT (Java_FOUND AND JNI_FOUND))
        message(STATUS "Java bindings disabled - Java/JNI not found")
        set(ENABLE_JAVA OFF)
    endif()
endif()

if(ENABLE_TCL)
    find_package(TCL)
    if(NOT TCL_FOUND)
        message(STATUS "Tcl bindings disabled - Tcl not found")
        set(ENABLE_TCL OFF)
    endif()
endif()

if(ENABLE_PERL)
    find_package(Perl COMPONENTS Interpreter Development)
    if(NOT PERL_FOUND)
        message(STATUS "Perl bindings disabled - Perl not found")
        set(ENABLE_PERL OFF)
    endif()
endif()

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

# Add language bindings if enabled
if(ENABLE_PYTHON)
    find_package(Python3 COMPONENTS Interpreter Development)
    if(Python3_FOUND)
        add_subdirectory(bindings/Python)
    else()
        message(STATUS "Python bindings disabled - Python3 not found")
        set(ENABLE_PYTHON OFF)
    endif()
endif()

if(ENABLE_JAVA)
    find_package(Java COMPONENTS Development)
    find_package(JNI)
    if(Java_FOUND AND JNI_FOUND)
        add_subdirectory(bindings/Java)
    else()
        message(STATUS "Java bindings disabled - Java/JNI not found")
        set(ENABLE_JAVA OFF)
    endif()
endif()

if(ENABLE_TCL)
    find_package(TCL)
    if(TCL_FOUND)
        add_subdirectory(bindings/Tcl)
    else()
        message(STATUS "Tcl bindings disabled - Tcl not found")
        set(ENABLE_TCL OFF)
    endif()
endif()

if(ENABLE_PERL)
    find_package(Perl COMPONENTS Interpreter Development)
    if(PERL_FOUND)
        add_subdirectory(bindings/Perl)
    else()
        message(STATUS "Perl bindings disabled - Perl not found")
        set(ENABLE_PERL OFF)
    endif()
endif()

# Configure and install pkg-config files
set(prefix ${CMAKE_INSTALL_PREFIX})
set(exec_prefix \${prefix})
set(libdir \${exec_prefix}/${CMAKE_INSTALL_LIBDIR})
set(includedir \${prefix}/${CMAKE_INSTALL_INCLUDEDIR})
set(VERSION ${PROJECT_VERSION})

# Main pkg-config file
configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/pilot-link.pc.in
    ${CMAKE_CURRENT_BINARY_DIR}/pilot-link.pc
    @ONLY
)

# Additional pkg-config file for preprocessor flags
configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/pilot-link-pp.pc.in
    ${CMAKE_CURRENT_BINARY_DIR}/pilot-link-pp.pc
    @ONLY
)

# Install pkg-config files
install(FILES 
    ${CMAKE_CURRENT_BINARY_DIR}/pilot-link.pc
    ${CMAKE_CURRENT_BINARY_DIR}/pilot-link-pp.pc
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig
)

# Install m4 macros
configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/pilot-link.m4.in
    ${CMAKE_CURRENT_BINARY_DIR}/pilot-link.m4
    @ONLY
)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/pilot-link.m4
        DESTINATION ${CMAKE_INSTALL_DATADIR}/aclocal)

# Install documentation files if directory exists
if(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/doc)
    install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/doc/
            DESTINATION ${CMAKE_INSTALL_DOCDIR}
            COMPONENT documentation
            PATTERN "doxygen.cfg*" EXCLUDE
            PATTERN "*.in" EXCLUDE
            PATTERN "html" EXCLUDE
            PATTERN "xml" EXCLUDE
    )
endif()

# Install header files
install(DIRECTORY include/
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/pilot-link
        COMPONENT development
        FILES_MATCHING PATTERN "*.h"
        PATTERN "pi-version.h.in" EXCLUDE)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/include/pi-version.h
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/pilot-link
        COMPONENT development)
