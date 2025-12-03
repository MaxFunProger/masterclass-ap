cmake_minimum_required(VERSION 3.20)

project(masterclasses_service LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(userver COMPONENTS core postgresql REQUIRED)

add_executable(masterclasses-service
    src/main.cpp
    src/handlers/ping_handler.cpp
    src/handlers/mc_list_handler.cpp
    src/handlers/mc_add_handler.cpp
    src/handlers/mc_add_bulk_handler.cpp
    src/handlers/mc_delete_handler.cpp
    src/handlers/user_add_handler.cpp
    src/handlers/user_delete_handler.cpp
)

target_include_directories(masterclasses-service PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
)

target_link_libraries(masterclasses-service PRIVATE
    userver::core
    userver::postgresql
)

