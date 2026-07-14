cmake_minimum_required(VERSION 3.16)
project(Tide-island-config-app LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Gui Quick QuickControls2)

qt_add_executable(Tide-island-config-app
    main.cpp
    resources.qrc
)

target_link_libraries(Tide-island-config-app PRIVATE
    Qt6::Gui
    Qt6::Quick
    Qt6::QuickControls2
)
