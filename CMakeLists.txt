cmake_minimum_required(VERSION 3.1)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -D_DEBUG -Wno-deprecated-declarations")
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -gdwarf-3")
set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -gdwarf-3")

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "/home/user/Work/project/build/unoptimized_linux")
set(CMAKE_BINARY_DIR "/home/user/Work/project/build/unoptimized_linux")
set(SHARED_DIR "/home/user/Work/project/shared")

######################
# use macros "library"
######################
include(utils.cmake)

set(CMAKE_SOURCE_DIR ${PROJECT_SOURCE_DIR})
set(CMAKE_CONFIGURATION_TYPES "debug_x64" "release_x64" "unoptimized_x64")
set(CMAKE_CONFIGURATION_TYPES "${CMAKE_CONFIGURATION_TYPES}" CACHE STRING
		"Reset the configurations to what we need" FORCE)

set(project_source_dir ${CMAKE_SOURCE_DIR})

set(PROJECT_TRUNK_DIR                    "${project_source_dir}")
set(PROJECT_SHARED_DIR                   "${project_source_dir}/../shared")
set(PROJECT_SHARED_BUILD_DIR             "${project_source_dir}/../shared/BUILD")
set(PROJECT_CONFIGS_DIR                  "${project_source_dir}/bin/configs")
set(PROJECT_SCRIPTS_DIR                  "${project_source_dir}/bin/scripts")
set(PROJECT_BOOST_INCLUDE                "${PROJECT_SHARED_DIR}/boost")
set(PROJECT_LIBXML_INCLUDE               "${PROJECT_SHARED_DIR}/libxml2/include")
set(PROJECT_LIBPQ_INCLUDE                "${PROJECT_SHARED_DIR}/postgresql/src/interfaces/libpq")
set(PROJECT_HTMLCXX_INCLUDE              "${PROJECT_SHARED_DIR}/htmlcxx/html")


include_directories(
		${PROJECT_TRUNK_DIR}
		${PROJECT_SHARED_DIR}
		${PROJECT_BOOST_INCLUDE}
		${PA_LIBXML_INCLUDE}
		${PROJECT_LIBPQ_INCLUDE}
		${PROJECT_LIBPQ_INCLUDE}
		${LIBPQ_HTMLCXX_INCLUDE}
)

########################################
# create cmake projects for all binaries
########################################

create_project_with_exports("core")
create_shared_library_excl("/rem/" true)

create_project_with_exports("configs")
create_shared_library_excl("/rem/" true)

create_project_with_exports("templates")
create_shared_library_excl("/rem/" true)

create_project_with_exports("datamodel")
create_shared_library_excl("/rem/" true)

create_project_with_exports("common")
create_shared_library_excl("/rem/" true)

create_project_with_exports("worker")
create_shared_library_excl("/rem/" true)

create_project_with_exports("server")
create_shared_library_excl("/rem/" true)

create_project_with_exports("datatypes")
create_shared_library_excl("/rem/" true)

# add dummy target for CLion to activate intellisense on this projects, not for building
add_custom_target(INTELLISENSE
        COMMAND
        DEPENDS core configs templates datamodel common worker server datatypes
    )

# add forwarding-targets for building via plain make
add_custom_target(total COMMAND make all config=debug_x64 -j 8 -C ${PROJECT_SOURCE_DIR} CLION_EXE_DIR=${CMAKE_BINARY_DIR})
add_custom_target(purge COMMAND make clean config=debug_x64 -j 8 -C ${PROJECT_SOURCE_DIR} CLION_EXE_DIR=${CMAKE_BINARY_DIR})
