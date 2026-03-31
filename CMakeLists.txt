cmake_minimum_required(VERSION 3.20)

project(masterclasses_service LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(userver COMPONENTS core postgresql REQUIRED)

file(READ src/sql/select_masterclasses_filtered.sql _tmp)
string(STRIP "${_tmp}" SQL_SELECT_MASTERCLASSES_FILTERED)

file(READ src/sql/select_masterclasses_filtered_date_asc.sql _tmp)
string(STRIP "${_tmp}" SQL_SELECT_MASTERCLASSES_FILTERED_DATE_ASC)

file(READ src/sql/select_masterclasses_filtered_date_desc.sql _tmp)
string(STRIP "${_tmp}" SQL_SELECT_MASTERCLASSES_FILTERED_DATE_DESC)

file(READ src/sql/insert_masterclass.sql _tmp)
string(STRIP "${_tmp}" SQL_INSERT_MASTERCLASS)

file(READ src/sql/delete_masterclass.sql _tmp)
string(STRIP "${_tmp}" SQL_DELETE_MASTERCLASS)

file(READ src/sql/select_user_by_phone.sql _tmp)
string(STRIP "${_tmp}" SQL_SELECT_USER_BY_PHONE)

file(READ src/sql/exists_user_by_phone.sql _tmp)
string(STRIP "${_tmp}" SQL_EXISTS_USER_BY_PHONE)

file(READ src/sql/insert_user.sql _tmp)
string(STRIP "${_tmp}" SQL_INSERT_USER)

file(READ src/sql/select_user_profile.sql _tmp)
string(STRIP "${_tmp}" SQL_SELECT_USER_PROFILE)

file(READ src/sql/delete_user_requests.sql _tmp)
string(STRIP "${_tmp}" SQL_DELETE_USER_REQUESTS)

file(READ src/sql/insert_favorite.sql _tmp)
string(STRIP "${_tmp}" SQL_INSERT_FAVORITE)

file(READ src/sql/delete_favorite.sql _tmp)
string(STRIP "${_tmp}" SQL_DELETE_FAVORITE)

file(READ src/sql/select_favorites.sql _tmp)
string(STRIP "${_tmp}" SQL_SELECT_FAVORITES)

file(READ src/sql/select_masterclasses_by_ids.sql _tmp)
string(STRIP "${_tmp}" SQL_SELECT_MASTERCLASSES_BY_IDS)

configure_file(
    src/sql/queries.hpp.in
    ${CMAKE_CURRENT_BINARY_DIR}/generated/sql/queries.hpp
    @ONLY
)

add_executable(masterclasses-service
    src/main.cpp
    src/handlers/ping_handler.cpp
    src/handlers/mc_list_handler.cpp
    src/handlers/mc_add_handler.cpp
    src/handlers/mc_delete_handler.cpp
    src/handlers/auth_register_handler.cpp
    src/handlers/auth_login_handler.cpp
    src/handlers/user_delete_handler.cpp
    src/handlers/user_profile_handler.cpp
    src/handlers/user_favorites_handler.cpp
    src/handlers/static_image_handler.cpp
    src/utils/phone.cpp
)

target_include_directories(masterclasses-service PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_BINARY_DIR}/generated
)

target_link_libraries(masterclasses-service PRIVATE
    userver::core
    userver::postgresql
)
