# Target output file
ifeq ($(strip $(PROJKIND)),exe)
TARGETNAME ?= $(PROJNAME)
else ifeq ($(strip $(PROJKIND)),lib)
TARGETNAME ?= lib$(PROJNAME).a
else ifeq ($(strip $(PROJKIND)),so)
TARGETNAME ?= lib$(PROJNAME).so
CFLAGS += -fPIC
else
$(error PROJKIND should be 'exe' or 'lib' or 'so')
endif 
TARGET = $(OUTDIR)/$(TARGETNAME)

# Compile/link flags
COMMONFLAGS = $(GCC_COMMONFLAGS) -Wall -g $(addprefix -D,$(DEFINE)) $(addprefix -I ,$(INCLUDEPATH))
ASFLAGS = $(GCC_ASFLAGS) 
CFLAGS = $(GCC_CFLAGS) -std=gnu99
CPPFLAGS = $(GCC_CPPFLAGS)
LDFLAGS = $(GCC_LDFLAGS) -Wl,-rpath=\$${ORIGIN}
ARFLAGS = $(GCC_ARFLAGS)

# debug vs release
ifeq ($(strip $(CONFIG)),debug)
COMMONFLAGS += -D_DEBUG -O0
else ifeq ($(strip $(CONFIG)),release)
COMMONFLAGS += -DNDEBUG -O2
else
$(error CONFIG should be 'debug' or 'release')
endif

# Object files
ASSOURCES ?= $(wildcard $(addsuffix /*.S,$(SRCDIR)))
OBJS ?= $(addprefix $(OBJDIR)/,$(notdir $(ASSOURCES:%.S=%.o) $(CSOURCES:%.c=%.o) $(CPPSOURCES:%.cpp=%.o)))

# Setup VPATH to find source files
VPATH = $(sort $(dir $(ASSOURCES) $(CSOURCES) $(CPPSOURCE)))

# .h file dependencies
-include $(OBJS:.o=.d)

# Tool-chain
PREFIX	 ?= 
CC	= $(PREFIX)gcc
CPP	= $(PREFIX)g++
AS	= $(CC)
LD	= $(PREFIX)g++
AR	= $(PREFIX)ar

# Flags to generate .d files
DEPGENFLAGS = -MD -MF $(@:%.o=%.d) -MT $@  -MP 

# Assemble Rule
$(OBJDIR)/%.o: %.S
	@echo "  AS    $@"
	@mkdir -p $(@D)
	@$(AS) $(COMMONFLAGS) $(ASFLAGS) -c -o $@ $(abspath $<)

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

# Link Rule (exe)
$(TARGET): $(PRECOMPILE_TARGETS) $(OBJS) $(LINKPROJECTLIBS)
	@echo "  LD    $(notdir $@)"
	@$(LD) $(LDFLAGS) -o $@ $^ $(LIBS) $(GCC_LIBS)

# Run target for exe
run: target
	@$(TARGET)

list-libs:
	@echo -n

copy-target: $(COPYTARGET)

else ifeq ($(strip $(PROJKIND)),so)

# Link Rule (so)
$(TARGET): $(PRECOMPILE_TARGETS) $(OBJS) $(LINKPROJECTLIBS)
	@echo "  LD    $(notdir $@)"
	@$(LD) $(LDFLAGS) -shared -Wl,-soname,$(notdir $@) -o $@ $^ $(LIBS) $(GCC_LIBS)

list-libs:
	@echo $(abspath $(TARGET))" "

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
