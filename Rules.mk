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
OTHERLIBS += ${shell for x in $(LINKPROJECTS); do \
				make CONFIG=$(CONFIG) -s -C $$x list-libs; \
			 done }

# C and C++ source files
CSOURCES ?= $(wildcard *.c)
CPPSOURCES ?= $(wildcard *.cpp)

# Preprocessor
INCLUDEPATH	+=
DEFINE += 

# Output Directory
OUTDIR = ./bin/$(CONFIG)

# Tool chain name
ifeq ($(OS),Windows_NT)
TOOLCHAIN ?= msvc
else
TOOLCHAIN ?= gcc
endif


# Include toolchain specific rules
include $(RULESDIR)/Rules-$(TOOLCHAIN).mk

# List target
list-target:
	@echo -n $(TARGET)

# Clean
clean-this:
	@echo "  CLEAN "`pwd`
	@rm -rf *.pdb $(OUTDIR) $(EXTRACLEAN)

# Clean just this project
rebuild-this: clean-this target

# Make sub-projects
sub-projects:
	@for dir in $(SUBPROJECTS) $(LINKPROJECTS) ; do \
		make CONFIG=$(CONFIG) -s -C $$dir; \
	done
	@for dir in $(COPYPROJECTS) ; do \
		make CONFIG=$(CONFIG) COPYTARGETTO=$(abspath $(OUTDIR)) -s -C $$dir copy-target; \
	done

# Clean sub-projects
clean-sub-projects:
	@for dir in $(SUBPROJECTS) $(LINKPROJECTS) ; do \
		make CONFIG=$(CONFIG) -s -C $$dir clean; \
	done

# Clean everything
clean: clean-this clean-sub-projects

# Rebuild
rebuild: clean target

# Target
target: sub-projects $(TARGET)
