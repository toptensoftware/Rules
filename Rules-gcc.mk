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
OBJS ?= $(addprefix $(OUTDIR)/,$(CSOURCES:%.c=%.o) $(CPPSOURCES:%.cpp=%.o))

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

# Compile C Rule
$(OUTDIR)/%.o: %.c
	@echo "  CC    $(notdir $@)"
	@mkdir -p $(@D)
	@$(CC) $(COMMONFLAGS) $(CFLAGS) $(DEPGENFLAGS) -c -o $@ $<

# Compile C++ Rule
$(OUTDIR)/%.o: %.cpp
	@echo "  CPP   $(notdir $@)"
	@mkdir -p $(@D)
	@$(CPP) $(COMMONFLAGS) $(CPPFLAGS) $(DEPGENFLAGS) -c -o $@ $<

# Rule to copy target file to a super-project specified output directory
COPYTARGET=$(COPYTARGETTO)/$(notdir $(TARGET))
$(COPYTARGET): $(TARGET)
	@echo "  CP    "$(notdir $@)
	@mkdir -p $(@D)
	@cp $< $@


ifeq ($(strip $(PROJKIND)),exe)

# Link Rule (exe)
$(TARGET): $(OBJS) $(LINKPROJECTLIBS)
	@echo "  LD    $(notdir $@)"
	@$(LD) $(LDFLAGS) -o $@ $^ $(LIBS)

# Run target for exe
run: target
	@$(TARGET)

list-libs:
	@echo -n

copy-target: $(COPYTARGET)

else ifeq ($(strip $(PROJKIND)),so)

# Link Rule (so)
$(TARGET): $(OBJS) $(LINKPROJECTLIBS)
	@echo "  LD    $(notdir $@)"
	@$(LD) $(LDFLAGS) -shared -Wl,-soname,$(notdir $@) -o $@ $^ $(LIBS)

list-libs:
	@echo $(abspath $(TARGET))" "

copy-target: $(COPYTARGET)

else ifeq ($(strip $(PROJKIND)),lib)

# Library Rule
$(TARGET): $(OBJS)
	@echo "  AR    $(notdir $@)"
	@$(AR) cr $@ $(OBJS)

list-libs:
	@echo -n $(abspath $(TARGET))" "

copy-target:

endif
