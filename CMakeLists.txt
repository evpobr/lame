cmake_minimum_required(VERSION 3.13)

project(lame VERSION 3.100 LANGUAGES C)

include(CheckFunctionExists)
include(CheckTypeSize)
include(CheckIncludeFile)
include(CheckLibraryExists)
include(GNUInstallDirs)

list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake)

include(CheckCPUArch)

set(STDC_HEADERS 1)

find_library(LIBM_LIBRARY m)
if(LIBM_LIBRARY)
  check_library_exists(${LIBM_LIBRARY} floor "" HAVE_FLOOR_IN_M)
endif()

check_include_file(stdint.h HAVE_STDINT_H)
check_include_file(errno.h HAVE_ERRNO_H)
check_include_file(inttypes.h HAVE_INTTYPES_H)
check_include_file(limits.h HAVE_LIMITS_H)
check_include_file(unistd.h HAVE_UNISTD_H)
check_include_file(fcntl.h HAVE_FCNTL_H)

check_include_file(termcap.h HAVE_TERMCAP_H)
check_include_file(ncurses/termcap.h HAVE_NCURSES_TERMCAP_H)

check_type_size(int8_t INT8_T)
check_type_size(int16_t INT16_T)
check_type_size(int32_t INT32_T)
check_type_size(int64_t INT64_T)

check_function_exists(strchr HAVE_STRCHR)
check_function_exists(memcpy HAVE_MEMCPY)

check_cpu_arch_x86(CPU_TYPE_X86)
check_cpu_arch_x64(CPU_TYPE_X64)

if(CPU_TYPE_X86 OR CPU_TYPE_X64)
    check_include_file(xmmintrin.h HAVE_XMMINTRIN_H)
endif()

set(LIB_WITH_DECODER ON)

include(CMakePackageConfigHelpers)

set(mpglib_SRCS
  mpglib/common.c
  mpglib/dct64_i386.c
  mpglib/decode_i386.c
  mpglib/interface.c
  mpglib/layer1.c
  mpglib/layer2.c
  mpglib/layer3.c
  mpglib/tabinit.c
  mpglib/common.h
  mpglib/dct64_i386.h
  mpglib/decode_i386.h
  mpglib/huffman.h
  mpglib/interface.h
  mpglib/l2tables.h
  mpglib/layer1.h
  mpglib/layer2.h
  mpglib/layer3.h
  mpglib/mpg123.h
  mpglib/mpglib.h
  mpglib/tabinit.h
)

add_library(mp3lame
  include/lame.h
  ${mpglib_SRCS}
  libmp3lame/VbrTag.c
  libmp3lame/bitstream.c
  libmp3lame/encoder.c
  libmp3lame/fft.c
  libmp3lame/gain_analysis.c
  libmp3lame/id3tag.c
  libmp3lame/lame.c
  libmp3lame/newmdct.c
  libmp3lame/presets.c
  libmp3lame/psymodel.c
  libmp3lame/quantize.c
  libmp3lame/quantize_pvt.c
  libmp3lame/reservoir.c
  libmp3lame/set_get.c
  libmp3lame/tables.c
  libmp3lame/takehiro.c
  libmp3lame/util.c
  libmp3lame/vbrquantize.c
  libmp3lame/version.c
  libmp3lame/mpglib_interface.c
  libmp3lame/VbrTag.h
  libmp3lame/bitstream.h
  libmp3lame/encoder.h
  libmp3lame/fft.h
  libmp3lame/gain_analysis.h
  libmp3lame/id3tag.h
  libmp3lame/l3side.h
  libmp3lame/lame-analysis.h
  libmp3lame/lame_global_flags.h
  libmp3lame/lameerror.h
  libmp3lame/machine.h
  libmp3lame/newmdct.h
  libmp3lame/psymodel.h
  libmp3lame/quantize.h 
  libmp3lame/quantize_pvt.h
  libmp3lame/reservoir.h
  libmp3lame/set_get.h
  libmp3lame/tables.h
  libmp3lame/util.h
  libmp3lame/vbrquantize.h
  libmp3lame/version.h
)

add_library(mp3lame::mp3lame ALIAS mp3lame)

# Tune x86 and x86_64
if(CPU_TYPE_X86 OR CPU_TYPE_X64)
  target_compile_definitions(mp3lame
    PRIVATE
      USE_FAST_LOG
      TAKEHIRO_IEEE754_HACK
  )
  if(HAVE_XMMINTRIN_H)
    target_sources(mp3lame
        PRIVATE
          libmp3lame/vector/xmm_quantize_sub.c
          libmp3lame/vector/lame_intrin.h
    )
    target_compile_definitions(mp3lame PRIVATE MIN_ARCH_SSE)
  endif()

  # Try to use NASM
  if(CPU_TYPE_X86)
    enable_language(ASM_NASM)
    list(APPEND CMAKE_ASM_NASM_SOURCE_FILE_EXTENSIONS nas)
    if(CMAKE_ASM_NASM_COMPILER_WORKS)
      set(HAVE_NASM 1)
      set(MMX_choose_table 1)
      target_sources(mp3lame
        PRIVATE
          libmp3lame/i386/nasm.h
          libmp3lame/i386/choose_table.nas
          libmp3lame/i386/cpu_feat.nas
          libmp3lame/i386/fft3dn.nas
          libmp3lame/i386/fftsse.nas
      )
    endif()
  endif()
endif()

target_compile_definitions(mp3lame
  PRIVATE
    HAVE_CONFIG_H
    HAVE_MPGLIB
    DECODE_ON_THE_FLY
)
if(MSVC)
  target_compile_definitions(mp3lame PRIVATE _CRT_SECURE_NO_WARNINGS)
endif()

target_include_directories(mp3lame
  PUBLIC
    $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
  PRIVATE
    libmp3lame
    mpglib
    ${PROJECT_BINARY_DIR}
)

target_link_libraries(mp3lame PRIVATE $<$<BOOL:${HAVE_FLOOR_IN_M}>:${LIBM_LIBRARY}>)

if(BUILD_SHARED_LIBS)
  set_target_properties(mp3lame PROPERTIES
    VERSION 0.0.0
    SOVERSION 0)
  if(WIN32)
    target_sources(mp3lame
      PRIVATE
        include/lame.def
        libmp3lame/lame.rc
    )
  elseif(CMAKE_SYSTEM_NAME STREQUAL Darwin)
    target_link_options(mp3lame PRIVATE LINKER:-exported_symbols_list,${PROJECT_SOURCE_DIR}/cmake/libmp3lame.exp)
  elseif(UNIX AND (CMAKE_COMPILER_IS_GNUCC OR (CMAKE_C_COMPILER_ID STREQUAL "Clang")))
    target_link_options(mp3lame PRIVATE LINKER:--version-script,${PROJECT_SOURCE_DIR}/cmake/libmp3lame.ver)
  endif()
  if(MSVC)
    set_property(TARGET mp3lame PROPERTY RUNTIME_OUTPUT_NAME lame_enc)
  elseif(MINGW OR CYGWIN)
    set_property(TARGET mp3lame PROPERTY RUNTIME_OUTPUT_NAME mp3lame-0)
  endif()
endif()

find_package(SndFile 1.0.2)
find_package(Curses)

set_property(TARGET mp3lame PROPERTY PUBLIC_HEADER include/lame.h)

configure_file(cmake/config.h.cmake config.h)

install(TARGETS mp3lame EXPORT mp3lame-targets
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

export(EXPORT mp3lame-targets NAMESPACE mp3lame:: FILE mp3lame-targets.cmake)
install(EXPORT mp3lame-targets
  DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/mp3lame
  NAMESPACE mp3lame::
)

configure_package_config_file(${PROJECT_SOURCE_DIR}/cmake/mp3lame-config.cmake.in mp3lame-config.cmake
  INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/mp3lame
  NO_SET_AND_CHECK_MACRO
  NO_CHECK_REQUIRED_COMPONENTS_MACRO
)

write_basic_package_version_file(${CMAKE_CURRENT_BINARY_DIR}/mp3lame-config-version.cmake COMPATIBILITY AnyNewerVersion)

install(
  FILES
    ${CMAKE_CURRENT_BINARY_DIR}/mp3lame-config.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/mp3lame-config-version.cmake
  DESTINATION
    ${CMAKE_INSTALL_LIBDIR}/cmake/mp3lame
)

# lame encoder

add_executable(lame
  frontend/lame_main.c
  frontend/main.c
  frontend/main.h
  frontend/brhist.c
  frontend/brhist.h
  frontend/console.c
  frontend/console.h
  frontend/get_audio.c
  frontend/get_audio.h
  frontend/lametime.c
  frontend/lametime.h
  frontend/parse.c
  frontend/parse.h
  frontend/timestatus.c
  frontend/timestatus.h
)
target_compile_definitions(lame
  PRIVATE
    HAVE_CONFIG_H
)
target_include_directories(lame
  PRIVATE
    libmp3lame
    ${PROJECT_BINARY_DIR}
)
target_link_libraries(lame PRIVATE mp3lame)
if(SndFile_FOUND)
  target_compile_definitions(lame PRIVATE LIBSNDFILE)
  target_link_libraries(lame PRIVATE SndFile::sndfile)
endif()
if(CURSES_FOUND)
  message("CURSES_HAVE_CURSES_H: ${CURSES_HAVE_CURSES_H}")
  message("CURSES_HAVE_NCURSES_H: ${CURSES_HAVE_NCURSES_H}")
  message("CURSES_HAVE_NCURSES_NCURSES_H: ${CURSES_HAVE_NCURSES_NCURSES_H}")
  message("CURSES_HAVE_NCURSES_CURSES_H: ${CURSES_HAVE_NCURSES_CURSES_H}")
  target_compile_definitions(lame PRIVATE HAVE_NCURSES_TERMCAP_H)
  target_include_directories(lame PRIVATE ${CURSES_INCLUDE_DIRS})
  target_link_libraries(lame PRIVATE ${CURSES_LIBRARIES})
endif()

install(TARGETS lame
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
