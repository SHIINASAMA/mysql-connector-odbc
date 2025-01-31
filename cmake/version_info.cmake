# Copyright (c) 2024, Oracle and/or its affiliates.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License, version 2.0, as
# published by the Free Software Foundation.
#
# This program is designed to work with certain software (including
# but not limited to OpenSSL) that is licensed under separate terms, as
# designated in a particular file or component or in included license
# documentation. The authors of MySQL hereby grant you an additional
# permission to link the program and your derivative works with the
# separately licensed software that they have either included with
# the program or referenced in the documentation.
#
# Without limiting anything contained in the foregoing, this file,
# which is part of Connector/C++, is also subject to the
# Universal FOSS Exception, version 1.0, a copy of which can be found at
# https://oss.oracle.com/licenses/universal-foss-exception.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License, version 2.0, for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA


if(NOT DEFINED SHOW_VERSION_INFO AND MAINTAINER_MODE)
  set(SHOW_VERSION_INFO 1)
endif()

get_filename_component(VERSION_INFO_HOME "${CMAKE_CURRENT_LIST_DIR}/version_info" ABSOLUTE CACHE)


#
# Add Windows version info resources to the library/executable file produced
# by target TGT.
#
# This is ignored on non-Windows platforms. The second argument is a string
# to use as `FileDescription` attribute. If another argument is given, it
# is used for `Comments` attribute.
#
# Note: Version information is taken from version.cmake file included by
# gen_version_info.cmake script that generates resource definitions.
#
#

function(add_version_info TGT DESCR)

  if(NOT WIN32)
    return()
  endif()

  get_target_property(TYPE ${TGT} TYPE)

  # Currently setting version resources for static libraries does not work.
  # Possibly because of the machinery we use to merge static library from
  # several smaller ones. For now we can live without version info in static
  # libraries.

  if(TYPE STREQUAL "STATIC_LIBRARY")
    return()
  endif()

  set(out "${CMAKE_CURRENT_BINARY_DIR}/${TGT}_version_info.rc")

  # Command to generate .rc file with version information. This is done
  # by the gen_version_info.cmake script which uses version_info.rc.in template.

  add_custom_command(OUTPUT "${out}"
    COMMAND ${CMAKE_COMMAND}
      -D "RC=${out}"
      -D "OUTPUT=$<TARGET_FILE:${TGT}>"
      -D "TYPE=${TYPE}"
      -D "DESCRIPTION=${DESCR}"
      -D "COMMENTS=${ARGN}"
      -D "VERSION=${CMAKE_SOURCE_DIR}/version.cmake"
      -D "CONFIG=$<CONFIG>"
      -P "${VERSION_INFO_HOME}/gen_version_info.cmake"
  )

  # Add the generated .rc file to the sources of the target.

  target_sources(${TGT} PRIVATE "${out}")

  if(SHOW_VERSION_INFO)
    show_version_info(${TGT})
  endif()

  #add_custom_command(TARGET ${TGT} POST_BUILD
  #  COMMAND ${CMAKE_COMMAND} -E rm -rf "${out}"
  #)

  message(STATUS "generated version info for target ${TGT} (${TYPE}): ${out}")

endfunction()

#
# Arrange for a library/executable target TGT to show the version information
# resources once its file is generated.
#
# This command is ignored on non-Windows platforms or if the target does not
# exist.
#

function(show_version_info TGT)

  if(NOT WIN32 OR NOT TARGET ${TGT})
    return()
  endif()

  add_custom_command(TARGET ${TGT} POST_BUILD
  COMMAND ${CMAKE_COMMAND}
    -D FILE=$<TARGET_FILE:${TGT}>
    -P "${VERSION_INFO_HOME}/show_version_info.cmake"
  )

endfunction()

