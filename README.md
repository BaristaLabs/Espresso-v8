# Automated V8 Builds using Azure DevOps

This packages contain prebuilt V8 binaries, debug symbols, headers and
libraries required to embed the V8 JavaScript engine into a C++ project.

> Note: This repository contains V8 builds targeting VS2019 and a different set of GN_Options used for Espresso. See [this repository](https://github.com/pmed/v8-nuget) for a richer set of target environments.

| Package                     | Version
|-----------------------------|----------------------------------------------------------------------------------------------------------------------|
|V8 x86 for Visual Studio 2019|[![NuGet](https://img.shields.io/nuget/v/BaristaLabs.Espresso.v8-win-x86.svg)](https://www.nuget.org/packages/BaristaLabs.Espresso.v8-win-x86/)|
|V8 x64 for Visual Studio 2019|[![NuGet](https://img.shields.io/nuget/v/BaristaLabs.Espresso.v8-win-x64.svg)](https://www.nuget.org/packages/BaristaLabs.Espresso.v8-win-x64/)|

## Usage

To use V8 in a project install the package `BaristaLabs.Espresso.v8.win-$Platform.$Version`
from a console with `nuget install` command or from inside of Visual Studio
(see menu option *Tools -> NuGet Package Manager -> Manage NuGet Packages for Solution...*)
where

  * `$Platform` is a target platform type, currently `x86` or `x64`.

  * `$Version` is the actual V8 version, one of https://chromium.googlesource.com/v8/v8.git/+refs

There are 3 package kinds:

  * `BaristaLabs.Espresso.v8.win-$Platform.$Version` - contains developer header and 
    library files; depends on `v8.redist` package

  * `BaristaLabs.Espresso.v8.win-redist-$Platform.$Version` - prebuilt V8 binaries:
    dlls, blobs, etc.

  * `BaristaLabs.Espresso.v8.win-symbols-$PlatformToolset-$Platform.$Version` - debug symbols for V8:
    [pdb files](https://en.wikipedia.org/wiki/Program_database)

After successful packages installation add `#include <v8.h>` in a C++  project
and build it. All necessary files (*.lib, *.dll, *.pdb) would be referenced
in the project automatically with MsBuild property sheets.


## How to build

This section is mostly for the package maintainers who wants to update V8.

Tools required to build V8 NuGet package on Windows:

  * Visual C++ toolset (version >=2013)
  * Python 2.X
  * Git
  * NuGet (https://dist.nuget.org/index.html)

To build V8 and make NuGet packages:

  1. Run `build.py` with optional command-line arguments.
  2. Publish `nuget/*.nupkg` files after successful build.
  
Build script `build.py` supports command-line arguments to specify package build options:

  1. V8 version branch/tag name (or `V8_VERSION` environment variable), default is `lkgr` branch
  2. Target platform (or `PLATFORM` evnironment variable), default is [`x86`, `x64`]
  3. Configuration (or `CONFIGURATION` environment variable), default is [`Debug`, `Release`]
  4. XP platofrm toolset usage flag (or `XP` environment variable), default is not set
