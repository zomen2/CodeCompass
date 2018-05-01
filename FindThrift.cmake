# - Try to find LibThrift
#  LIBTHRIFT_FOUND - System has LibThrift
#  LIBTHRIFT_INCLUDE_DIRS - The LibThrift include directories
#  LIBTHRIFT_LIBRARIES - The libraries needed to use LibThrift
#  LIBTHRIFT_DEFINITIONS - Compiler switches required for using LibThrift


find_package(PkgConfig)
pkg_check_modules(PC_LIBTHRIFT QUIET "libthrift")
set(LIBTHRIFT_DEFINITIONS ${PC_LIBTHRIFT_CFLAGS_OTHER})

find_path(libthrift_INCLUDE_DIR
        NAMES thrift/Thrift.h
        HINTS ${PC_LIBTHRIFT_INCLUDE_DIR})

find_library(libthrift_LIBRARY
	NAMES thrift libthrift
	HINTS
		${THIRFT_LIBRARY_PATH}
		${PC_LIBTHIRFT_LIBRARY_DIRS})

find_path(libthrift_JAVA_DIR
        NAMES libthrift-0.10.0.jar libthrift-0.11.0.jar
        HINTS
                ${libthrift_INCLUDE_DIR}/../lib/java
        NO_DEFAULT_PATH)

find_program(thrift_BIN
	NAMES thrift
	HINTS
		${libthrift_INCLUDE_DIR}/../bin)

set(THRIFT_LIBTHRIFT_INCLUDE_DIRS ${libthrift_INCLUDE_DIR} CACHE STRING "Thrift libthrift include dirs")
set(THRIFT_LIBTHRIFT_LIBRARIES ${libthrift_LIBRARY} CACHE STRING "Thrift libthrift library")
set(THRIFT_LIBTHRIFT_JARS_DIR ${libthrift_JAVA_DIR} CACHE STRING "Thrift java jars")
set(THRIFT_EXECUTABLE ${thrift_BIN} CACHE STRING "Thrift executable")

if(THRIFT_LIBTHRIFT_INCLUDE_DIRS AND THRIFT_LIBTHRIFT_LIBRARIES)
	set(THRIFT_LIBTHRIFT_FOUND TRUE)
endif()

if(THRIFT_LIBTHRIFT_JARS_DIR)
	set(THRIFT_LIBTHRIFT_JAR_FOUND TRUE)
endif()

# TODO: These not appears in the generated makefiles. Are they necessary?
set(THRIFT_INCLUDE_DIRS ${THRIFT_LIBTHRIFT_INCLUDE_DIRS})
set(THRIFT_LIBRARIES ${THRIFT_LIBTHRIFT_LIBRARIES})
set(THRIFT_JARS_DIR ${THRIFT_LIBTHRIFT_JARS_DIR})
