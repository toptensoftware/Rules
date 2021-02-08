# Target output file
ifeq ($(strip $(PROJKIND)),exe)
TARGETNAME ?= $(PROJNAME).exe
else ifeq ($(strip $(PROJKIND)),lib)
TARGETNAME ?= $(PROJNAME).lib
else ifeq ($(strip $(PROJKIND)),so)
TARGETNAME ?= $(PROJNAME).dll
else
$(error PROJKIND should be 'exe' or 'lib' or 'so')
endif 
TARGET = $(OUTDIR)/$(TARGETNAME)

# Compile/link flags
COMMONFLAGS = $(MSVC_COMMONFLAGS) 
COMMONFLAGS += $(addprefix /D,$(DEFINE)) 
COMMONFLAGS += $(addprefix /I,$(INCLUDEPATH)) 
COMMONFLAGS += /Zi /Fd$(OUTDIR)/ /showIncludes /W1 /Zc:wchar_t /FC
COMMONFLAGS += /D_UNICODE /DUNICODE /D_WINDOWS
CFLAGS = $(MSVC_CFLAGS)
CPPFLAGS = $(MSVC_CPPFLAGS)
LDFLAGS = /DEBUG $(MSVC_LDFLAGS)
ARFLAGS = $(MSVC_ARFLAGS)

# debug vs release
ifeq ($(strip $(CONFIG)),debug)
COMMONFLAGS += /D_DEBUG /Od
else ifeq ($(strip $(CONFIG)),release)
COMMONFLAGS += /DNDEBUG /O2 /Oi
LDFLAGS += /OPT:REF /OPT:ICF
else
$(error CONFIG should be 'debug' or 'release')
endif

# Object files
OBJS ?= $(addprefix $(OUTDIR)/,$(CSOURCES:%.c=%.obj) $(CPPSOURCES:%.cpp=%.obj))

# .h file dependencies
-include $(OBJS:.obj=.d)

# Tool-chain
PREFIX	 ?= 
CC	= node $(RULESDIR)/cl-filter cl
CPP	= node $(RULESDIR)/cl-filter cl
LD = link
AR = lib


# Pre-compiled C header

ifneq ($(strip $(PCH_C)),)

PCH_C_H := $(PCH_C:%.c=%.h)
PCH_C_OBJ := $(OUTDIR)/$(PCH_C:%.c=%.obj)
PCH_C_FILE := $(OUTDIR)/$(PCH_C:%.c=%.pch)
PCH_C_FLAGS := /Yu$(PCH_C_H) /Fp$(PCH_C_FILE)

$(PCH_C_OBJ): $(PCH_C)
	@echo "  PCH   $(notdir $@)"
	@mkdir -p $(@D)
	@$(CC) /nologo $(COMMONFLAGS) $(CFLAGS) /c $< /Fo$@ /Yc$(PCH_C_H) /Fp$(PCH_C_FILE)

endif

# Pre-compiled C++ header

ifneq ($(strip $(PCH_CPP)),)

PCH_CPP_H := $(PCH_CPP:%.cpp=%.h)
PCH_CPP_OBJ := $(OUTDIR)/$(PCH_CPP:%.cpp=%.obj)
PCH_CPP_FILE := $(OUTDIR)/$(PCH_CPP:%.cpp=%.pch)
PCH_CPP_FLAGS := /Yu$(PCH_CPP_H) /Fp$(PCH_CPP_FILE)

$(PCH_CPP_OBJ): $(PCH_CPP)
	@echo "  PCH   $(notdir $@)"
	@mkdir -p $(@D)
	@$(CPP) /nologo $(COMMONFLAGS) $(CPPFLAGS) /c $< /Fo$@ /Yc$(PCH_CPP_H) /Fp$(PCH_CPP_FILE)

endif

# Compile C Rule
$(OUTDIR)/%.obj: %.c $(PCH_C_OBJ)
	@echo "  CC    $(notdir $@)"
	@mkdir -p $(@D)
	@$(CC) /nologo $(COMMONFLAGS) $(CFLAGS) /c $< /Fo$@ $(PCH_C_FLAGS)

# Compile C++ Rule
$(OUTDIR)/%.obj: %.cpp $(PCH_CPP_OBJ)
	@echo "  CPP   $(notdir $@)"
	@mkdir -p $(@D)
	@$(CPP) /nologo $(COMMONFLAGS) $(CPPFLAGS) /c $< /Fo$@ $(PCH_CPP_FLAGS)

# Rule to copy target file to a super-project specified output directory
COPYTARGET=$(COPYTARGETTO)/$(notdir $(TARGET))
$(COPYTARGET): $(TARGET)
	@echo "  CP    "$(notdir $@)
	@mkdir -p $(@D)
	@cp $< $@


ifeq ($(strip $(PROJKIND)),exe)

# Link Rule (exe)
$(TARGET): $(OBJS) $(LINKPROJECTLIBS)
	@echo "  LINK  $(notdir $@)"
	@$(LD) /nologo $(LDFLAGS) $(LIBS) $(MSVC_LIBS) /out:$@ /pdb:$(@:%.exe=%.pdb) $^

# Run target for exe
run: target
	@$(TARGET)

list-libs:
	@echo -n

copy-target: $(COPYTARGET)

else ifeq ($(strip $(PROJKIND)),so)

# Link Rule (dll)
$(TARGET): $(OBJS) $(LINKPROJECTLIBS)
	@echo "  LINK  $(notdir $@)"
	@$(LD) /nologo /dll $(LDFLAGS) $(LIBS) /out:$@ $^

list-libs:
	@echo $(abspath $(TARGET:%.dll=%.lib))" "

copy-target: $(COPYTARGET)

else ifeq ($(strip $(PROJKIND)),lib)

# Library Rule
$(TARGET): $(OBJS)
	@echo "  LIB   $(notdir $@)"
	@$(AR) /nologo /out:$@ $(OBJS)

list-libs:
	@echo -n $(abspath $(TARGET))" "

copy-target:

endif
