# Find libusb
#
# This module defines:
#  LibUSB_FOUND - True if libusb was found
#  LibUSB_INCLUDE_DIRS - Include directories
#  LibUSB_LIBRARIES - Libraries to link against
#  LibUSB_VERSION - Version string

include(FindPackageHandleStandardArgs)

find_package(PkgConfig QUIET)
if(PKG_CONFIG_FOUND)
    pkg_check_modules(PC_LIBUSB QUIET libusb)
endif()

find_path(LibUSB_INCLUDE_DIR
    NAMES usb.h
    PATHS
        ${PC_LIBUSB_INCLUDE_DIRS}
        /usr/include
        /usr/local/include
)

find_library(LibUSB_LIBRARY
    NAMES usb
    PATHS
        ${PC_LIBUSB_LIBRARY_DIRS}
        /usr/lib
        /usr/lib64
        /usr/local/lib
        /usr/local/lib64
)

set(LibUSB_VERSION ${PC_LIBUSB_VERSION})

find_package_handle_standard_args(LibUSB
    FOUND_VAR LibUSB_FOUND
    REQUIRED_VARS
        LibUSB_LIBRARY
        LibUSB_INCLUDE_DIR
    VERSION_VAR LibUSB_VERSION
)

if(LibUSB_FOUND)
    set(LibUSB_LIBRARIES ${LibUSB_LIBRARY})
    set(LibUSB_INCLUDE_DIRS ${LibUSB_INCLUDE_DIR})
endif()

mark_as_advanced(
    LibUSB_INCLUDE_DIR
    LibUSB_LIBRARY
)
