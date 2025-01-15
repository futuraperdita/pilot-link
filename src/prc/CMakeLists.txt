# Include GNUInstallDirs for installation paths
include(GNUInstallDirs)

# Install PRC files
install(FILES
    getrom.prc
    getrom2.prc
    DESTINATION ${CMAKE_INSTALL_DATADIR}/pilot-link/prc
)
