cmake_minimum_required(VERSION 3.16)

project(MyTask VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Sql Network Multimedia)
find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick LinguistTools)

qt_standard_project_setup(REQUIRES 6.10)

qt_add_executable(appMyTask
    main.cpp
    databasemanager.cpp
    databasemanager.h
    taskmodel.cpp
    taskmodel.h
    resources.qrc
    languagemanager.cpp
    languagemanager.h
    app.rc
)

qt_add_qml_module(appMyTask
    URI MyTask
    VERSION 1.0
    QML_FILES
        Main.qml
)

qt_add_translations(appMyTask
    TS_FILES
        uk_UA.ts
        ru_RU.ts
    RESOURCE_PREFIX "/i18n"
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
set_target_properties(appMyTask PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appMyTask
    PRIVATE
        Qt6::Quick
        Qt6::Sql
        Qt6::Network
        Qt6::Multimedia
)

install(TARGETS appMyTask
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)