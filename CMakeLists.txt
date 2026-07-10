# The following five lines of boilerplate have to be in your project's
# CMakeLists in this exact order for cmake to work correctly
cmake_minimum_required(VERSION 3.22)

set(EXTRA_COMPONENT_DIRS
    components
)

include($ENV{IDF_PATH}/tools/cmake/project.cmake)
project(esp32_usbhost)

# Hook objdump disassembly to the root project compilation
add_custom_command(TARGET app POST_BUILD
    COMMAND riscv32-esp-elf-objdump -S -d ${CMAKE_BINARY_DIR}/${CMAKE_PROJECT_NAME}.elf > ${CMAKE_BINARY_DIR}/${CMAKE_PROJECT_NAME}.lst
    COMMENT "Generating RISC-V source-interleaved disassembly: build/${CMAKE_PROJECT_NAME}.lst"
    VERBATIM
)
