
# Home directories
CCWHOME ?= $(RULESDIR)/..
CIRCLEHOME = $(CCWHOME)/circle

# For CCW this is hard coded to 1
STDLIB_SUPPORT = 1

# set this to "softfp" if you want to link specific libraries
FLOAT_ABI ?= hard

# Include paths
INCLUDEPATH	+= \
	$(CCWHOME)/include \
	$(CCWHOME)/src/nplib/include \
	$(CCWHOME)/src/ceelib/include \
	$(CCWHOME)/src/fatfs \
	$(CIRCLEHOME)/include \
	$(CIRCLEHOME)/addon \
	$(CIRCLEHOME)/addon/vc4 \
	$(CIRCLEHOME)/addon/vc4/interface/khronos/include

# Preprocessor defines
DEFINE += \
	__circle__ \
	RASPPI=$(RASPPI) \
	STDLIB_SUPPORT=$(STDLIB_SUPPORT) \
	__VCCOREVER__=0x04000000 


# Compile/link flags
COMMONFLAGS = $(GCC_COMMONFLAGS) -Wall -g $(addprefix -D,$(DEFINE)) $(addprefix -I ,$(INCLUDEPATH))
COMMONFLAGS += $(ARCH) -fsigned-char -ffreestanding 
COMMONFLAGS += -U__unix__ -U__linux__
CFLAGS = $(GCC_CFLAGS) -std=gnu99
CPPFLAGS = $(GCC_CPPFLAGS) --std=c++14 -Wno-aligned-new -fno-exceptions -fno-rtti -nostdinc++ -fno-threadsafe-statics
LDFLAGS = $(GCC_LDFLAGS) --section-start=.init=$(LOADADDR)
ARFLAGS = $(GCC_ARFLAGS)

# Default CCW lib
CCWLIB = $(CCWHOME)/src/ccw/bin/$(CONFIG)/libccw.a

# debug vs release
ifeq ($(strip $(CONFIG)),debug)
COMMONFLAGS += -D_DEBUG -O0
else ifeq ($(strip $(CONFIG)),release)
COMMONFLAGS += -DNDEBUG -O2
else
$(error CONFIG should be 'debug' or 'release')
endif

# Object files
OBJS ?= $(addprefix $(OBJDIR)/,$(CSOURCES:%.c=%.o) $(CPPSOURCES:%.cpp=%.o))

# .h file dependencies
-include $(OBJS:.o=.d)

# Tool-chain
PREFIX	 ?= 
CC	= $(PREFIX)gcc
CPP	= $(PREFIX)g++
AS	= $(CC)
LD	= $(PREFIX)ld
AR	= $(PREFIX)ar

# Architecture and Pi Model
ifeq ($(strip $(AARCH)),32)
ifeq ($(strip $(RASPPI)),1)
ARCH	?= -DAARCH=32 -mcpu=arm1176jzf-s -marm -mfpu=vfp -mfloat-abi=$(FLOAT_ABI)
KERNEL	?= kernel
else ifeq ($(strip $(RASPPI)),2)
ARCH	?= -DAARCH=32 -mcpu=cortex-a7 -marm -mfpu=neon-vfpv4 -mfloat-abi=$(FLOAT_ABI)
KERNEL	?= kernel7
else ifeq ($(strip $(RASPPI)),3)
ARCH	?= -DAARCH=32 -mcpu=cortex-a53 -marm -mfpu=neon-fp-armv8 -mfloat-abi=$(FLOAT_ABI)
KERNEL	?= kernel8-32
else ifeq ($(strip $(RASPPI)),4)
ARCH	?= -DAARCH=32 -mcpu=cortex-a72 -marm -mfpu=neon-fp-armv8 -mfloat-abi=$(FLOAT_ABI)
KERNEL	?= kernel7l
else
$(error RASPPI must be set to 1, 2, 3 or 4)
endif
LOADADDR = 0x8000
else ifeq ($(strip $(AARCH)),64)
ifeq ($(strip $(RASPPI)),3)
ARCH	?= -DAARCH=64 -mcpu=cortex-a53 -mlittle-endian -mcmodel=small
KERNEL	?= kernel8
else ifeq ($(strip $(RASPPI)),4)
ARCH	?= -DAARCH=64 -mcpu=cortex-a72 -mlittle-endian -mcmodel=small
KERNEL	?= kernel8-rpi4
else
$(error RASPPI must be set to 3 or 4)
endif
PREFIX	= $(PREFIX64)
LOADADDR = 0x80000
else
$(error AARCH must be set to 32 or 64)
endif

# Target output file
ifeq ($(strip $(PROJKIND)),exe)
TARGETNAME ?= $(KERNEL).img
else ifeq ($(strip $(PROJKIND)),lib)
TARGETNAME ?= lib$(PROJNAME).a
else
$(error PROJKIND should be 'exe' or 'lib')
endif 
TARGET = $(OUTDIR)/$(TARGETNAME)

# Default libraries
LIBGCC	  = $(shell $(CPP) $(ARCH) -print-file-name=libgcc.a)
LIBM	  = $(shell $(CPP) $(ARCH) -print-file-name=libm.a)

# Build full library list
LIBS += \
	$(CIRCLEHOME)/lib/libcircle.a \
	$(CIRCLEHOME)/lib/sched/libsched.a \
	$(CIRCLEHOME)/lib/input/libinput.a \
	$(CIRCLEHOME)/lib/usb/libusb.a \
	$(CIRCLEHOME)/lib/fs/libfs.a \
	$(CIRCLEHOME)/addon/vc4/interface/bcm_host/libbcm_host.a \
	$(CIRCLEHOME)/addon/SDCard/libsdcard.a \
	$(CIRCLEHOME)/addon/linux/liblinuxemu.a \
	$(CIRCLEHOME)/addon/vc4/interface/vcos/libvcos.a \
	$(CIRCLEHOME)/addon/vc4/interface/vmcs_host/libvmcs_host.a \
	$(CIRCLEHOME)/addon/vc4/vchiq/libvchiq.a \
	$(CIRCLEHOME)/addon/vc4/interface/khronos/libkhrn_client.a \
	$(CCWHOME)/src/fatfs/bin/$(CONFIG)/libfatfs.a \
	$(CCWHOME)/src/nplib/bin/$(CONFIG)/libnplib.a \
	$(CCWHOME)/src/ceelib/bin/$(CONFIG)/libceelib.a \
	$(LIBGCC) \
	$(LIBM)

# Flags to generate .d files
DEPGENFLAGS = -MD -MF $(@:%.o=%.d) -MT $@  -MP 

# Assemble
$(OBJDIR)/%.o: %.S
	@echo "  AS    $@"
	@$(AS) $(AFLAGS) -c -o $@ $<

# Compile C Rule
$(OBJDIR)/%.o: %.c
	@echo "  CC    $(notdir $@)"
	@mkdir -p $(@D)
	@$(CC) $(COMMONFLAGS) $(CFLAGS) $(DEPGENFLAGS) -c -o $@ $(abspath $<)

# Compile C++ Rule
$(OBJDIR)/%.o: %.cpp
	@echo "  CPP   $(notdir $@)"
	@mkdir -p $(@D)
	@$(CPP) $(COMMONFLAGS) $(CPPFLAGS) $(DEPGENFLAGS) -c -o $@ $(abspath $<)

# Rule to copy target file to a super-project specified output directory
COPYTARGET=$(COPYTARGETTO)/$(notdir $(TARGET))
$(COPYTARGET): $(TARGET)
	@echo "  CP    "$(notdir $@)
	@mkdir -p $(@D)
	@cp $< $@


ifeq ($(strip $(PROJKIND)),exe)

# Link Kernel image
$(TARGET): $(PRECOMPILE_TARGETS) $(OBJS) $(CCWLIB) $(LIBS) $(LINKPROJECTLIBS) $(CIRCLEHOME)/circle.ld
	@echo "  LD    $(notdir $(@:%.img=%.elf))"
	@$(LD) -o  $(@:%.img=%.elf) -Map $(@:%.img=%.map) $(LDFLAGS) \
		-T $(CIRCLEHOME)/circle.ld --no-warn-rwx-segments $(CRTBEGIN) $(OBJS) \
		--start-group $(CCWLIB) $(LIBS) $(LINKPROJECTLIBS) --end-group $(CRTEND)
	@echo "  DUMP  $(notdir $(@:%.img=%.lst))"
	@$(PREFIX)objdump -d $(@:%.img=%.elf) | $(PREFIX)c++filt > $(@:%.img=%.lst)
	@echo "  COPY  $(notdir $@)"
	@$(PREFIX)objcopy $(@:%.img=%.elf) -O binary $@
	@echo -n "  WC    $(notdir $@) [$(PROJNAME)] => "
	@wc -c < $@

list-libs:
	@echo -n

copy-target: $(COPYTARGET)

else ifeq ($(strip $(PROJKIND)),lib)

# Library Rule
$(TARGET): $(PRECOMPILE_TARGETS) $(OBJS)
	@echo "  AR    $(notdir $@)"
	@$(AR) cr $@ $(OBJS)

list-libs:
	@echo -n $(abspath $(TARGET))" "

copy-target:

endif






# Bootloader Flashing/Monitoring 

ifeq ($(strip $(PROJKIND)),exe)


SERIALPORT  ?= /dev/ttyUSB0
USERBAUD ?= 115200
FLASHBAUD ?= 115200
REBOOTMAGIC ?=

HEXFILE = $(TARGET:%.img=%.hex)

$(HEXFILE): $(TARGET)
	@echo "  COPY  $(notdir $(HEXFILE))"
	@$(PREFIX)objcopy $(<:%.img=%.elf) -O ihex $@

# Command line to run node and python.  
# Including the '.exe' forces WSL to run the Windows host version
# of these commands.  If putty and node are available on the windows 
# machine we can get around WSL's lack of serial port support
ifeq ($(strip $(WSL_DISTRO_NAME)),)
NODE=node 
PUTTY=putty
PUTTYSERIALPORT=$(SERIALPORT)
else
NODE=node.exe
PUTTY=putty.exe
PUTTYSERIALPORT=$(subst /dev/ttyS,COM,$(SERIALPORT))		# Remap to windows name
endif

ifeq ($(strip $(USEFLASHY)),)

# Flash with python
flash: $(HEXFILE)
ifneq ($(strip $(REBOOTMAGIC)),)
	python3 $(CIRCLEHOME)/tools/reboottool.py $(REBOOTMAGIC) $(SERIALPORT) $(USERBAUD)
endif
	python3 $(CIRCLEHOME)/tools/flasher.py $(HEXFILE) $(SERIALPORT) $(FLASHBAUD)

else

# Flash with flashy
flash: $(HEXFILE)
	$(NODE) $(CIRCLEHOME)/tools/flashy/flashy.js \
		$(SERIALPORT) \
		--flashBaud:$(FLASHBAUD) \
		--userBaud:$(USERBAUD) \
		--reboot:$(REBOOTMAGIC) \
		$(FLASHYFLAGS) \
		$(HEXFILE)

endif

# Monitor in putty
monitor:
	$(PUTTY) -serial $(PUTTYSERIALPORT) -sercfg $(USERBAUD)

# Monitor in terminal (Linux only)
cat:
	stty -F $(SERIALPORT) $(USERBAUD) cs8 -cstopb -parenb -icrnl
	cat $(SERIALPORT)

endif