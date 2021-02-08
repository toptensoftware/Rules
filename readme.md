# Rules

"Rules" is a set of GNU makefile scripts for building C and C++ projects under either GCC on Linux or MSVC 
on Windows.  It's super easy to setup, very little configuration and mostly just works out of the box.

* Automatically builds every source file in the project directory (C and C++ only, not sub-folders)
* Defaults to MSVC on Windows and GCC on Linux, other toolchains configurable
* .h dependency generation (including a custom filter script for MSVC to capture dependencies accurately)
* Support for sub-projects that are automatically built before the parent project
* Support for link-projects that are automatically built before and linked with the parent project
* Supports building executables, shared libraries (dll/so) and static libraries
* Debug and Release mode builds
* Builds to an output directory
* Automatic project name from the project directory name
* Platform independent settings for defines and include paths
* Platform dependent settings for MSVC vs GCC
* Helper targets for clean, rebuild and run
* Global configuration via optional user supplied Config.mk file
* Precompiled header support for MSVC (not GCC since it gives little benefit)

Rules was partially inspired by the makefile scripts in Rene Stange's [circle](https://github.com/rsta2/circle) project.

## Basic Usage

Here's a simple example of how to use Rules:

1. Create a project directory

2. Clone the Rules repository.  Where you put it doesn't really matter, but as a sub-directory of your
   project is often a good idea.  (if your project is under git control, as a submodule works well)

3. Create a Makefile in your project directory:

```
include ./Rules/Rules.mk
```

4. Create a C or C++ file in your project directory:

```cpp
#include <stdio.h>

int main()
{
    printf("Hello World\n");
    return 0;
}
```

5. Additional steps for MSVC:

    * Ensure NodeJS installed and available on the path.  (A simple node script is used to 
    process the output of the MSVC cl.exe compiler to pick up the .h file dependencies)

    * Run the Visual Studio vcvarsall script before running make so the environment is correctly 
    configured for command line builds.  There's a vcvars.bat file in the Rules folder that runs 
    the VS2019 Community edition version of these tools.

    * you'll need to have set of posix like commands available on your path, including GNU `make`, 
    `rm` etc...



Now, in the project directory run the following commands

* `make` - builds the project
* `make clean` - cleans the project (and all sub-projects)
* `make rebuild` - cleans and builds the project
* `make run` - runs the project

Other targets include `clean-this`, `rebuild-this`, `sub-projects` and `clean-sub-projects`.


# Project Settings

You can adjust your project, by adding the following variable declarations in the makefile 
before including the Rules.mk file.

* `PROJNAME` - changes the name of the project from the default (which is the directory name)
* `PROJKIND` - either `exe` for executable, `so` for shared library (ie: .so or .dll) or `lib` for a static library
* `SUBPROJECTS` - paths to a set of folders that will be made, cleaned etc... before this project.  These folders
should have makefiles to build the project and can be Rules based, or not.
* `LINKPROJECTS` - paths to a set of project folders that will be not only made with this project, but also linked with 
this project.  Generally these projects should use Rules as their build process and be either `lib` or `so` projects.
* `INCLUDEPATH` - a set of folders to be added to the compiler's include path
* `DEFINE` - a set of symbols to be defined for the compile
* `LIBS` - libraries to be passed to linker (platform independent)
* `CONFIG` - `debug` or `release`
* `OUTDIR` - where to place intermediate and build output files (defaults to `bin/$(CONFIG)`)
* `TOOLCHAIN` - the tool chain to be invoked for building.  Typically set automatically to either `msvc` or `gcc`
* `PCH_C` and `PCH_CPP` - the precompiled header source (C and/or C++) file for MSVC builds.  (eg: stdafx.cpp).  The 
   corresponding .h file is determined by changing the extension to .h
* `MSVC_CFLAGS` and `GCC_CFLAGS` - toolchain specific C compiler flags
* `MSVC_CPPFLAGS` and `GCC_CPPFLAGS` - toolchain specific C++ compiler flags
* `MSVC_LDFLAGS` and `GCC_LDFLAGS` - toolchain specific linker flags
* `MSVC_ARFLAGS` and `GCC_ARFLAGS` - toolchain specific librarian (archive) flags
* `MSVC_LIBS` and `GCC_LIBS` - toolchain specific libraries to link with


# Global Configuration

If you're using Rules to build a number of projects, you might have common settings across all projects.  These can be
configured in either `Config.mk` or `Config2.mk` in the parent directory of the Rules sub-directory.

If present, these files will be processed after your per-project settings (in the project make files), but before most of
`Rules.mk`.


# Creating New Toolchains

Rules includes two built-in toolchains - `msvc` and `gcc`.  You can create additional toolchains by defining a new file 
named `Rules-<custom_toolchain_name>.mk` in the Rules subdirectory and setting the TOOLCHAIN variable to select it.

See the existing `Rules-msvc` and `Rules-gcc` for how these files should be setup.

