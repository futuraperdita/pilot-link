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

# Create the shared library if enabled
if(BUILD_SHARED_LIBS)
    add_library(pisock SHARED ${PISOCK_SOURCES})
    set_target_properties(pisock PROPERTIES
        VERSION ${PROJECT_VERSION}
        SOVERSION ${PROJECT_VERSION_MAJOR}
        C_VISIBILITY_PRESET default
        VISIBILITY_INLINES_HIDDEN OFF
        POSITION_INDEPENDENT_CODE ON
        ENABLE_EXPORTS ON
    )
endif()

# Create the static library if enabled
if(BUILD_STATIC_LIBS)
    add_library(pisock_static STATIC ${PISOCK_SOURCES})
    set_target_properties(pisock_static PROPERTIES
        OUTPUT_NAME pisock
        POSITION_INDEPENDENT_CODE ON
    )
endif()

# Common settings for both libraries
foreach(target IN ITEMS pisock pisock_static)
    if(TARGET ${target})
        target_include_directories(${target}
            PUBLIC
                $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
                $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/include>
                $<INSTALL_INTERFACE:include/pilot-link>
            PRIVATE
                ${CMAKE_CURRENT_SOURCE_DIR}
                ${CMAKE_BINARY_DIR}
        )

        target_compile_definitions(${target}
            PUBLIC
                HAVE_CONFIG_H
                _GNU_SOURCE
            PRIVATE
                BUILDING_PISOCK
        )

        # Link dependencies
        target_link_libraries(${target}
            PRIVATE
                pthread
                dl
                m
        )

        if(ENABLE_THREADS)
            target_link_libraries(${target} PRIVATE Threads::Threads)
        endif()

        if(ENABLE_BLUETOOTH AND BLUEZ_FOUND)
            target_link_libraries(${target} PRIVATE ${BLUEZ_LIBRARIES})
            target_include_directories(${target} PRIVATE ${BLUEZ_INCLUDE_DIRS})
            target_compile_definitions(${target} PRIVATE HAVE_BLUEZ)
        endif()

        if(ENABLE_USB)
            if(LIBUSB_FOUND)
                target_link_libraries(${target} PRIVATE ${LIBUSB_LIBRARIES})
                target_include_directories(${target} PRIVATE ${LIBUSB_INCLUDE_DIRS})
            endif()
            target_compile_definitions(${target} PRIVATE HAVE_USB)
        endif()
    endif()
endforeach()

# Installation
if(BUILD_SHARED_LIBS)
    install(TARGETS pisock
        EXPORT PilotLinkTargets
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    )
endif()

if(BUILD_STATIC_LIBS)
    install(TARGETS pisock_static
        EXPORT PilotLinkTargets
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    )
endif()
