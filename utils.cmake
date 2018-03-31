cmake_minimum_required(VERSION 3.1)


# _VARNAME ~ cmake's notion of pointers
macro(filter_list_on_regex in_list_VARNAME regex out_list_VARNAME)  
  set(in_list ${${in_list_VARNAME}})

  set(in_list_rem)

  foreach(item ${in_list})
    string(REGEX MATCH ${regex} rem ${item})
    if(rem)
      list(APPEND in_list_rem ${item})
    endif()
  endforeach()
  
  if(in_list_rem)
    list(REMOVE_ITEM in_list ${in_list_rem})
  endif()

  set(${out_list_VARNAME} ${in_list})
endmacro()


macro(glob_recurse_excl dir out_PROJ_SRC_VARNAME out_PROJ_HDR_VARNAME exclude_regex)
  file(GLOB_RECURSE SRC "${dir}/*.cpp" "${dir}/*.cxx")
  set(SRC_FILTERED)
  filter_list_on_regex("SRC" "${exclude_regex}" "SRC_FILTERED")
  set(SRC ${SRC_FILTERED})
  filter_list_on_regex("SRC" "stdafx" "SRC_FILTERED")

  file(GLOB_RECURSE HDR "${dir}/*.h" "${dir}/*.hpp" "${dir}/*.ipp" "${dir}/*.g" "${dir}/*.bat")
  set(HDR_FILTERED)
  filter_list_on_regex("HDR" "${exclude_regex}" "HDR_FILTERED")
  set(HDR ${HDR_FILTERED})
  filter_list_on_regex("HDR" "stdafx" "HDR_FILTERED")

  set(${out_PROJ_SRC_VARNAME} ${SRC_FILTERED})
  set(${out_PROJ_HDR_VARNAME} ${HDR_FILTERED})
endmacro()


macro(make_header_only in_HDR_VARNAME)
  set(HDR ${${in_HDR_VARNAME}})
  foreach( File ${HDR} )
    set_source_files_properties(${File} PROPERTIES HEADER_FILE_ONLY TRUE)
  endforeach()
endmacro()


macro(create_project name)
  set(PROJ_NAME ${name})
endmacro()


macro(create_project_with_exports name)
  set(PROJ_NAME ${name})
  string(TOUPPER ${PROJ_NAME} PROJ_NAME_U)
  add_definitions(-D${PROJ_NAME_U}_EXPORTS)
endmacro()


macro(add_msvc_precompiled_header precompiled_header precompiled_source sources_var)
  if(WIN32)
    get_filename_component(precompiled_basename ${precompiled_header} NAME_WE)
    set(precompiled_binary "${CMAKE_CURRENT_BINARY_DIR}/${precompiled_basename}.pch")
    set(sources ${${sources_var}})
    
    set_source_files_properties(${sources}
                                PROPERTIES COMPILE_FLAGS "/Yu\"${PROJ_NAME}/${precompiled_header}\" /FI\"${precompiled_header}\" /Fp\"${precompiled_binary}\"")

    set_source_files_properties(${precompiled_source}
                                PROPERTIES COMPILE_FLAGS "/Yc\"${PROJ_NAME}/${precompiled_header}\" /Fp\"${precompiled_binary}\""
                                           OBJECT_OUTPUTS "${precompiled_binary}")

    list(APPEND ${sources_var} ${precompiled_source} ${precompiled_header})
  endif()
endmacro()


macro(create_shared_library_excl_g pattern_to_exclude_dirs grammar gens_strlist)
  set(PROJ_DIR "${PA_TRUNK_DIR}/${PROJ_NAME}")
  set(PROJ_SRC)
  set(PROJ_HDR)
  glob_recurse_excl(${PROJ_NAME} "PROJ_SRC" "PROJ_HDR" ${pattern_to_exclude_dirs})
  set(gens_fn ${gens_strlist})
  foreach(gen ${gens_fn})
    list(APPEND gens "${PROJ_DIR}/${gen}")
  endforeach()

  add_custom_command(
   OUTPUT ${gens}
   COMMAND java -jar ${PA_SHARED_DIR}/antlr3/antlr-3.5.2-complete-no-st3.jar "${PROJ_DIR}/${grammar}" -o "${PROJ_DIR}" "${PROJ_DIR}/${grammar}"
   DEPENDS "${PROJ_DIR}/${grammar}"
   MAIN_DEPENDENCY "${PROJ_DIR}/${grammar}"
   )

  add_library(${PROJ_NAME} SHARED ${PROJ_SRC} ${PROJ_HDR} ${gens})
  set_target_properties(${PROJ_NAME} PROPERTIES LINKER_LANGUAGE CXX)
endmacro()


macro(create_shared_library_excl pattern_to_exclude_dirs precompiled)
  set(PROJ_SRC)
  set(PROJ_HDR)
  glob_recurse_excl(${PROJ_NAME} "PROJ_SRC" "PROJ_HDR" ${pattern_to_exclude_dirs})
  list(APPEND PROJ_ALL_SOURCES ${PROJ_SRC} ${PROJ_HDR})

  if(${precompiled})
    add_msvc_precompiled_header("stdafx.h" "stdafx.cpp" "PROJ_ALL_SOURCES")
  endif()

  add_library(${PROJ_NAME} SHARED ${PROJ_ALL_SOURCES})
  set_target_properties(${PROJ_NAME} PROPERTIES LINKER_LANGUAGE CXX)
endmacro()


macro(create_exec_excl pattern_to_exclude_dirs)
  set(PROJ_SRC)
  set(PROJ_HDR)
  glob_recurse_excl(${PROJ_NAME} "PROJ_SRC" "PROJ_HDR" ${pattern_to_exclude_dirs})
  
  list(APPEND PROJ_ALL_SOURCES ${PROJ_SRC} ${PROJ_HDR})
  add_msvc_precompiled_header("stdafx.h" "stdafx.cpp" "PROJ_ALL_SOURCES")
  
  if(WIN32)
    add_executable(${PROJ_NAME} WIN32 ${PROJ_ALL_SOURCES})
  elseif(UNIX)
    add_executable(${PROJ_NAME} ${PROJ_ALL_SOURCES})
  endif()
  set_target_properties(${PROJ_NAME} PROPERTIES LINKER_LANGUAGE CXX)
endmacro()


macro(add_deps_all deps_strlist)
  set(deps ${deps_strlist})
  foreach(dep ${deps})
    string(STRIP ${dep} dep)
    if(NOT ${dep} STREQUAL "")
      target_link_libraries(${PROJ_NAME} "${PA_LINK_PREFIX}/${dep}")
    endif()
  endforeach()
endmacro()


macro(add_deps_debug deps_strlist)
  set(deps ${deps_strlist})
  foreach(dep ${deps})
    string(STRIP ${dep} dep)
    if(NOT ${dep} STREQUAL "")
      target_link_libraries(${PROJ_NAME} debug "${PA_LINK_PREFIX}/${dep}")
    endif()
  endforeach()
endmacro()


macro(add_deps_nondebug deps_strlist)
  set(deps ${deps_strlist})
  foreach(dep ${deps})
    string(STRIP ${dep} dep)
    if(NOT ${dep} STREQUAL "")
      target_link_libraries(${PROJ_NAME} optimized "${PA_LINK_PREFIX}/${dep}")
    endif()
  endforeach()
endmacro()


macro(add_deps_all_custom deps_strlist)
  set(deps ${deps_strlist})
  foreach(dep ${deps})
    string(STRIP ${dep} dep)
    target_link_libraries(${PROJ_NAME} "${dep}")
  endforeach()
endmacro()


macro(add_refs refs_strlist)
  set(refs ${refs_strlist})
  foreach(ref ${refs})
    string(STRIP ${ref} ref)
    list(APPEND new_refs ${ref})
  endforeach()
  add_dependencies(${PROJ_NAME} ${new_refs})
endmacro()


macro(show_files patterns_strlist)
  set(patterns ${patterns_strlist})
  
  list(APPEND PROJ_FILES)

  foreach(pattern ${patterns})
    file(GLOB_RECURSE pattern_files "${pattern}")
    list(APPEND PROJ_FILES ${pattern_files})
  endforeach()   

  add_custom_target(${PROJ_NAME} SOURCES ${PROJ_FILES})
endmacro()


macro(copy_files pattern dest)
  if(NOT PROJ_NAME OR ${PROJ_NAME} STREQUAL "")
    message(FATAL_ERROR "Project name not set at some point. Exiting.")
  endif()

  file(GLOB_RECURSE PROJ_FILES ${pattern})

  set(PROJ_SRC_DIR "${PA_TRUNK_DIR}/${PROJ_NAME}")
  string(REGEX REPLACE "${PROJ_SRC_DIR}/" "" PROJ_FILES_STR_RELATIVE "${PROJ_FILES}")

  set(PROJ_FILES ${PROJ_FILES_STR_RELATIVE})

  foreach(file ${PROJ_FILES})
    add_custom_command(TARGET ${PROJ_NAME} PRE_BUILD
                        COMMAND ${CMAKE_COMMAND} -E
                            copy ${CMAKE_CURRENT_SOURCE_DIR}/${file} ${dest}/${file}
                        COMMENT "Copying ${file}"
                       )
  endforeach()
endmacro()
