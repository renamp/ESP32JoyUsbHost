idf_component_register(
    SRCS 
        "test_main.c"
    INCLUDE_DIRS 
        "."
        "../../main/inc"
    REQUIRES unity usb_low_level
    WHOLE_ARCHIVE
)
