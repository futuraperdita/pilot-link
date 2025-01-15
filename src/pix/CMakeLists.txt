# Include GNUInstallDirs for installation paths
include(GNUInstallDirs)

# Install image files
install(FILES
    b1.gif
    b2.gif
    b3.gif
    b4.gif
    b5.gif
    b6.gif
    b7.gif
    case.gif
    casemask.xbm
    case.xbm
    DESTINATION ${CMAKE_INSTALL_DATADIR}/pilot-link/pix
)
