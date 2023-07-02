# Default build target if not specified in main make file
target:

# Path to this file
RULESDIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

# Name of this project (from the root makefile folder name)
PROJNAME ?= $(notdir $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST)))))

# Project kind 'exe', 'lib' or 'dll'
PROJKIND ?= exe

# debug or release?
CONFIG ?= debug

# List of subprojects to also build/clean
SUBPROJECTS ?= 

# List of subprojects to also build/clean and link with.
# These projects should all have a "list-libs" target that
# echos the name of the lib file to link with
LINKPROJECTS ?= 

# Convert sub-project libs to appropriate .so or .a file
LINKPROJECTLIBS = ${shell for x in $(LINKPROJECTS); do \
				make CONFIG=$(CONFIG) PLATFORM=$(PLATFORM) -s -C $$x list-libs; \
			 done }

SRCDIR ?= .

# C and C++ source files
CSOURCES ?= $(wildcard $(addsuffix /*.c,$(SRCDIR)))
CPPSOURCES ?= $(wildcard $(addsuffix /*.cpp,$(SRCDIR)))

# Preprocessor
INCLUDEPATH	+=
DEFINE += 

# Output Directory
OUTDIR ?= ./bin/$(CONFIG)/$(PLATFORM)

# Intermediate object file directory
OBJDIR ?= $(OUTDIR)

# Tool chain name
ifeq ($(OS),Windows_NT)
TOOLCHAIN ?= msvc
else
TOOLCHAIN ?= gcc
endif

TOOLCHAIN_RULES ?= $(RULESDIR)/Rules-$(TOOLCHAIN).mk

# Verbosity
VERBOSE ?= 0
ifeq ($(VERBOSE),1)
Q := 
else
Q := @
endif

# A set of additional build targets to run before compile
PRECOMPILE_TARGETS ?= 

# Include toolchain specific rules
include $(TOOLCHAIN_RULES)

# List target
list-target:
	@echo -n $(TARGET)

# Clean
clean:
	@echo "  CLEAN "`pwd`
	$(Q)rm -rf *.pdb $(OUTDIR) $(EXTRACLEAN)

# Clean just this project
rebuild: clean target

# Make sub-projects
sub-projects:
	@for dir in $(SUBPROJECTS) $(LINKPROJECTS) ; do \
		make CONFIG=$(CONFIG) PLATFORM=$(PLATFORM) VERBOSE=$(VERBOSE) --no-print-directory -C $$dir; \
	done
	@for dir in $(COPYPROJECTS) ; do \
		make CONFIG=$(CONFIG) PLATFORM=$(PLATFORM) VERBOSE=$(VERBOSE) COPYTARGETTO=$(abspath $(OUTDIR))  --no-print-directory -C $$dir copy-target; \
	done

# Clean everything
clean-all: clean
	@for dir in $(SUBPROJECTS) $(LINKPROJECTS) ; do \
		make CONFIG=$(CONFIG) PLATFORM=$(PLATFORM) VERBOSE=$(VERBOSE) --no-print-directory -C $$dir clean-all; \
	done

# Rebuild
rebuild-all: clean-all target

# Target
target: sub-projects $(TARGET)
