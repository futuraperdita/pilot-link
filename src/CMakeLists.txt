# Add subdirectories
add_subdirectory(prc)
add_subdirectory(pix)

# Include GNUInstallDirs for installation paths
include(GNUInstallDirs)

# Find required packages
find_package(PNG)
find_package(PkgConfig REQUIRED)
pkg_check_modules(POPT popt)

# Build static userland library
add_library(piuserland STATIC
    plu_args.c
    userland.c
)

target_include_directories(piuserland
    PUBLIC
        ${CMAKE_SOURCE_DIR}/include
        ${CMAKE_BINARY_DIR}/include
        ${CMAKE_BINARY_DIR}
    PRIVATE
        ${POPT_INCLUDE_DIRS}
)

# Link piuserland against pisock
target_link_libraries(piuserland 
    PUBLIC 
        pisock
)

# List of all executables
set(PILOT_PROGRAMS
    pilot-addresses
    pilot-clip
    pilot-csd
    pilot-debugsh
    pilot-dedupe
    pilot-dlpsh
    pilot-file
    pilot-foto
    pilot-getram
    pilot-getrom
    pilot-getromtoken
    pilot-hinotes
    pilot-install-datebook
    pilot-install-expenses
    pilot-install-hinote
    pilot-install-memo
    pilot-install-netsync
    pilot-install-todo
    pilot-install-todos
    pilot-install-user
    pilot-memos
    pilot-nredir
    pilot-read-expenses
    pilot-read-ical
    pilot-read-notepad
    pilot-read-palmpix
    pilot-read-screenshot
    pilot-read-todos
    pilot-read-veo
    pilot-reminders
    pilot-schlep
    pilot-foto-treo600
    pilot-foto-treo650
    pilot-wav
    pilot-xfer
)

# Build each executable
foreach(PROG ${PILOT_PROGRAMS})
    # Handle special case for pilot-install-datebook which needs parsedate.y
    if(${PROG} STREQUAL "pilot-install-datebook")
        find_package(BISON REQUIRED)
        BISON_TARGET(ParseDate parsedate.y ${CMAKE_CURRENT_BINARY_DIR}/parsedate.c)
        add_executable(${PROG} 
            ${PROG}.c
            ${BISON_ParseDate_OUTPUT_SOURCE}
        )
    else()
        add_executable(${PROG} ${PROG}.c)
    endif()

    # Common include directories and link libraries
    target_include_directories(${PROG} PRIVATE
        ${CMAKE_SOURCE_DIR}/include
        ${CMAKE_BINARY_DIR}/include
        ${CMAKE_BINARY_DIR}
        ${POPT_INCLUDE_DIRS}
    )

    target_compile_definitions(${PROG} PRIVATE
        HAVE_CONFIG_H
        _GNU_SOURCE
    )

    # Link order matters - link against piuserland which pulls in pisock
    target_link_libraries(${PROG} PRIVATE
        piuserland
        ${POPT_LIBRARIES}
        pthread
        dl
        m
    )

    # Set RPATH
    set_target_properties(${PROG} PROPERTIES
        BUILD_WITH_INSTALL_RPATH TRUE
        INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib"
        INSTALL_RPATH_USE_LINK_PATH TRUE
    )

    # Special handling for programs that need PNG
    if(${PROG} MATCHES "pilot-read-(notepad|palmpix|veo|screenshot)")
        if(PNG_FOUND)
            target_include_directories(${PROG} PRIVATE ${PNG_INCLUDE_DIRS})
            target_link_libraries(${PROG} PRIVATE PNG::PNG)
        endif()
    endif()

    # Install the executable
    install(TARGETS ${PROG}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    )
endforeach()

# Handle Perl scripts if Perl is found
find_package(Perl)
if(PERL_FOUND)
    set(PERL_SCRIPTS
        pilot-ietf2datebook
        pilot-undelete
        pilot-sync-plan
    )

    foreach(SCRIPT ${PERL_SCRIPTS})
        add_custom_command(
            OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${SCRIPT}
            COMMAND ${PERL_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/${SCRIPT}.pl > ${CMAKE_CURRENT_BINARY_DIR}/${SCRIPT}
            COMMAND chmod +x ${CMAKE_CURRENT_BINARY_DIR}/${SCRIPT}
            DEPENDS ${SCRIPT}.pl
            COMMENT "Generating ${SCRIPT}"
        )
        add_custom_target(${SCRIPT}_target ALL DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${SCRIPT})
        install(PROGRAMS ${CMAKE_CURRENT_BINARY_DIR}/${SCRIPT}
                DESTINATION ${CMAKE_INSTALL_BINDIR}
                PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE
                          GROUP_READ GROUP_EXECUTE
                          WORLD_READ WORLD_EXECUTE)
    endforeach()
endif()
