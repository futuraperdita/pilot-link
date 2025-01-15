# All source files
set(PISOCK_SOURCES
    socket.c
    pi-buffer.c
    utils.c
    threadsafe.c
    debug.c
    connect.c
    serial.c
    sys.c
    syspkt.c
    padp.c
    slp.c
    net.c
    cmp.c
    dlp.c
    inet.c
    address.c
    appinfo.c
    contact.c
    datebook.c
    expense.c
    hinote.c
    location.c
    blob.c
    calendar.c
    mail.c
    md5.c
    memo.c
    money.c
    notepad.c
    palmpix.c
    pi-file.c
    pi-header.c
    todo.c
    veo.c
    versamail.c
    unixserial.c
)

# Add Bluetooth support if enabled
if(ENABLE_BLUETOOTH AND BLUEZ_FOUND)
    list(APPEND PISOCK_SOURCES bluetooth.c)
endif()

# USB backend based on platform
if(ENABLE_USB)
    if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
        list(APPEND PISOCK_SOURCES usb.c linuxusb.c)
    elseif(CMAKE_SYSTEM_NAME STREQUAL "FreeBSD")
        list(APPEND PISOCK_SOURCES usb.c freebsdusb.c)
    elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
        list(APPEND PISOCK_SOURCES usb.c darwinusb.c)
    else()
        # Default to libusb on other platforms
        find_package(PkgConfig REQUIRED)
        pkg_check_modules(LIBUSB REQUIRED libusb)
        list(APPEND PISOCK_SOURCES usb.c libusb.c)
    endif()
endif()

# Create the library
add_library(pisock SHARED ${PISOCK_SOURCES})
target_include_directories(pisock
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
        $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/include>
        $<INSTALL_INTERFACE:include/pilot-link>
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${CMAKE_BINARY_DIR}
)

target_compile_definitions(pisock
    PUBLIC
        HAVE_CONFIG_H
        _GNU_SOURCE
    PRIVATE
        BUILDING_PISOCK
)

# Link dependencies
target_link_libraries(pisock
    PRIVATE
        pthread
        dl
        m
)

if(ENABLE_THREADS)
    target_link_libraries(pisock PRIVATE Threads::Threads)
endif()

if(ENABLE_BLUETOOTH AND BLUEZ_FOUND)
    target_link_libraries(pisock PRIVATE ${BLUEZ_LIBRARIES})
    target_include_directories(pisock PRIVATE ${BLUEZ_INCLUDE_DIRS})
    target_compile_definitions(pisock PRIVATE HAVE_BLUEZ)
endif()

if(ENABLE_USB)
    if(LIBUSB_FOUND)
        target_link_libraries(pisock PRIVATE ${LIBUSB_LIBRARIES})
        target_include_directories(pisock PRIVATE ${LIBUSB_INCLUDE_DIRS})
    endif()
    target_compile_definitions(pisock PRIVATE HAVE_USB)
endif()

set_target_properties(pisock PROPERTIES
    VERSION ${PROJECT_VERSION}
    SOVERSION ${PROJECT_VERSION_MAJOR}
    C_VISIBILITY_PRESET default
    VISIBILITY_INLINES_HIDDEN OFF
    POSITION_INDEPENDENT_CODE ON
    ENABLE_EXPORTS ON
)

# Installation
install(TARGETS pisock
    EXPORT PilotLinkTargets
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
