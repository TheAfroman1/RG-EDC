# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026-present RG EDC
cmake_minimum_required(VERSION 3.16)
project(rgedc-shell LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick Multimedia Network)
find_package(PkgConfig REQUIRED)
pkg_check_modules(SDL2 REQUIRED IMPORTED_TARGET sdl2)

add_executable(rgedc-shell
  src/main.cpp
  src/gamepad.cpp src/gamepad.h
  src/system.cpp src/system.h
  src/library.cpp src/library.h
  src/spectrum.cpp src/spectrum.h
  src/phone.cpp src/phone.h
)
target_compile_definitions(rgedc-shell PRIVATE RGEDC_SOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}")
target_link_libraries(rgedc-shell PRIVATE
  Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick Qt6::Multimedia Qt6::Network PkgConfig::SDL2)

install(TARGETS rgedc-shell RUNTIME DESTINATION bin)
install(DIRECTORY qml/ DESTINATION share/rgedc-shell/qml)
install(DIRECTORY fonts/ DESTINATION share/rgedc-shell/fonts)
