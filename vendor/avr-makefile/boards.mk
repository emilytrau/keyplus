#######################################################################
#                             binary dirs                             #
#######################################################################

# Object files directory
OBJ_DIR = $(BUILD_DIR)/$(BOARD)-$(MCU)/obj

# Director were output files are placed
BUILD_TARGET_DIR = $(BUILD_DIR)/$(BOARD)-$(MCU)

# Where dependency files are placed
DEP_DIR = $(OBJ_DIR)/.dep

#######################################################################
#                        board config options                         #
#######################################################################

# Note: Specific board configs are stored in the `boards` directory.

ifndef BOARD_DIR
    BOARD_DIR = boards
endif

ifndef BOARD
    BOARD = default
endif

ifndef BUILD_DIR
    BUILD_DIR = build
endif

TARGET_BOARD_DIR := $(BOARD_DIR)/$(BOARD)

ifneq ("$(wildcard $(TARGET_BOARD_DIR)/config.mk)","")
    BOARD_MAKEFILE=$(TARGET_BOARD_DIR)/config.mk
    INC_PATHS += -I$(TARGET_BOARD_DIR)
    include $(BOARD_MAKEFILE)
    MAKEFILE_INC += $(BOARD_MAKEFILE)
    TARGET = $(TARGET_BASE_NAME)-$(BOARD)-$(MCU)
else
    $(error "Unknown board $(BOARD)")
endif

#######################################################################
#                         Target output files                         #
#######################################################################

TARGET_HEX = $(BUILD_TARGET_DIR)/$(TARGET).hex
TARGET_ELF = $(BUILD_TARGET_DIR)/$(TARGET).elf
TARGET_FUSE = $(BUILD_TARGET_DIR)/$(TARGET).fuse
TARGET_LOCK = $(BUILD_TARGET_DIR)/$(TARGET).lock
TARGET_EEP = $(BUILD_TARGET_DIR)/$(TARGET).eep
TARGET_LSS = $(BUILD_TARGET_DIR)/$(TARGET).lss
TARGET_SYM = $(BUILD_TARGET_DIR)/$(TARGET).sym
TARGET_MAP = $(BUILD_TARGET_DIR)/$(TARGET).map
