# Find readline
#
# This module defines:
#  Readline_FOUND - True if readline was found
#  Readline_INCLUDE_DIRS - Include directories
#  Readline_LIBRARIES - Libraries to link against

include(FindPackageHandleStandardArgs)

find_path(Readline_INCLUDE_DIR
    NAMES readline/readline.h
    PATHS
        /usr/include
        /usr/local/include
)

find_library(Readline_LIBRARY
    NAMES readline
    PATHS
        /usr/lib
        /usr/local/lib
)

# Readline often requires ncurses
find_library(Ncurses_LIBRARY
    NAMES ncurses
    PATHS
        /usr/lib
        /usr/local/lib
)

find_package_handle_standard_args(Readline
    FOUND_VAR Readline_FOUND
    REQUIRED_VARS
        Readline_LIBRARY
        Readline_INCLUDE_DIR
)

if(Readline_FOUND)
    set(Readline_INCLUDE_DIRS ${Readline_INCLUDE_DIR})
    if(Ncurses_LIBRARY)
        set(Readline_LIBRARIES ${Readline_LIBRARY} ${Ncurses_LIBRARY})
    else()
        set(Readline_LIBRARIES ${Readline_LIBRARY})
    endif()
endif()

mark_as_advanced(
    Readline_INCLUDE_DIR
    Readline_LIBRARY
    Ncurses_LIBRARY
)
