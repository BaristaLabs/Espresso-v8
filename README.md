# Espresso-v8

This package contains scripts and configuration to perform automated multi-platform V8 Builds using Azure DevOps and publish the resulting binaries to NuGet. These pre-built V8 libraries and headers then can be used to embed the V8 JavaScript engine into multi-platform C++ projects.

> Note: This repository contains V8 targeting win-VS2019, macOS, and linux on various platforms using a different set of GN_Options used for BaristaLabs.Espresso which may change over time. See [this repository](https://github.com/pmed/v8-nuget) for different windows-based platform toolsets.

[![Build Status](https://dev.azure.com/baristalabs/Espresso-v8/_apis/build/status/Espresso-v8-CI?branchName=master)](https://dev.azure.com/baristalabs/Espresso-v8/_build/latest?definitionId=3&branchName=master)

| Package                     | Version
|-----------------------------|----------------------------------------------------------------------------------------------------------------------|
|V8 Windows x86|[![NuGet](https://img.shields.io/nuget/v/BaristaLabs.Espresso.v8-monolith.win.ia32.release.svg)](https://www.nuget.org/packages/BaristaLabs.Espresso.v8-monolith.win.ia32.release/)|
|V8 Windows x64|[![NuGet](https://img.shields.io/nuget/v/BaristaLabs.Espresso.v8-monolith.win.x64.release.svg)](https://www.nuget.org/packages/BaristaLabs.Espresso.v8-monolith.win.x64.release/)|
|V8 macOS x64|[![NuGet](https://img.shields.io/nuget/v/BaristaLabs.Espresso.v8-monolith.macOS.x64.release.svg)](https://www.nuget.org/packages/BaristaLabs.Espresso.v8-monolith.macOS.x64.release/)|
|V8 Linux x64|[![NuGet](https://img.shields.io/nuget/v/BaristaLabs.Espresso.v8-monolith.linux.x64.release.svg)](https://www.nuget.org/packages/BaristaLabs.Espresso.v8-monolith.linux.x64.release/)|

## Usage

Most people who find this project want to simply embed the pre-built v8 binaries from nuget mentioned above into a C++ project.

To use V8 in a project install the package `BaristaLabs.Espresso.v8.win-$Configuration.$Version`
from a console with `nuget install` command or from inside of Visual Studio
(see menu option *Tools -> NuGet Package Manager -> Manage NuGet Packages for Solution...*)
where

  * `$Configuration` is a target v8 pre-defined configuration, such as `ia32.release` or `x64.release`.

  * `$Version` is the actual V8 version, one of https://chromium.googlesource.com/v8/v8.git/+refs

After successful packages installation add `#include <v8.h>` in a C++ project
and build it. In Visual Studio 2019, all necessary files (*.lib) would be referenced
in the project automatically with MsBuild property sheets.

This is not currently true for macOS and Linux using Visual Studio for Mac or other IDEs.

As this is a static release build, ensure that /MT is set.

## How to build and publish in Azure Devops

Simply fork this repo, reference it in Azure Devops project, create a new YAML build pipeline, select the azure-pipelines.yml file from this repo and queue a build.

The included pipeline will check for the latest version of v8 against the nuget package name and build, pack and push a new nuget package if outdated. The author of this project uses a nightly trigger to check for new, stable v8 releases and automatically publish new builds.

Consumers of this project might want to change the package name or publish to a private nuget feed, those exercises are left to the reader.

## How to build and publish in a local dev environment

Ensure that build dependencies have been are installed in the approprate environments.

See the following for a reference: https://v8.dev/docs/build

Also, in windows, install the Windows 10 SDK separately from Visual Studio 2019: https://developer.microsoft.com/en-US/windows/downloads/windows-10-sdk (See Note Below))
   
Ensure the Debugging tools are installed as it is required.

To build V8 and make NuGet packages:

Simply run through the powershell scripts sequentially for the target environment.
Use the azure-pipelines.yml as a guide for the inputs.

``` Powershell
./scripts/checkReleaseStatus # Determine which releases need to be built.
```

#### Windows

``` Powershell
./scripts/win-self-hosted/win-build-v8-1.ps1 # Download v8 Build Dependencies
./scripts/win/win-build-v8-2.ps1 -V8_VERSION 8.4.371.19 # Fetch a specific v8 version from source
./scripts/win/win-build-v8-3.ps1 # Build v8
./scripts/win/win-build-v8-4.ps1 # Generate nuspec and props
```

#### Linux
``` Powershell
./scripts/linux/linux-build-v8-1.ps1 # Download v8 Build Dependencies
./scripts/linux/linux-build-v8-2.ps1 -V8_VERSION 8.4.371.19 # Fetch a specific v8 version from source
./scripts/linux/linux-build-v8-3.ps1 # Build v8
./scripts/linux/linux-build-v8-4.ps1 # Generate nuspec and props
```

### macOS
``` Powershell
./scripts/macOS/macOS-build-v8-1.ps1 # Download v8 Build Dependencies
./scripts/macOS/macOS-build-v8-2.ps1 -V8_VERSION 8.4.371.19 # Fetch a specific v8 version from source
./scripts/macOS/macOS-build-v8-3.ps1 # Build v8
./scripts/macOS/macOS-build-v8-4.ps1 # Generate nuspec and props
```

Once the 4 scripts have been run, package/push using NuGet.

``` Powershell
nuget pack
nuget push *.nupkg -ApiKey <apikey> -Source https://api.nuget.org/v3/index.json
```

> Note: Visit https://omahaproxy.appspot.com/ for a list of the V8 versions that correspond to a Chrome build.


> Note: When building on Windows, installing the Windows 10 SDK as part of the Visual Studio 2019 installation is insufficient as it does not include the 'Debugging Tools for Windows' feature
> Ensure that is included by first removing (the latest) Windows 10 SDK using the Visual Studio 2019 installer then installing the Windows 10 SDK from https://developer.microsoft.com/en-us/windows/downloads/windows-10-sdk/ ensuring that 'Debugging Tools for Windows' is selected when installing.

> Note: When building with Docker on Windows, ensure that Hyper-V isolation is used over WSL2 and a good amount of cpus and ram is allocated in the docker settings - or, possibly it is possible to use WSL2 mode but  the number of CPUs with --cpus=4 - ancedontally on at 16 core windows machine with docker in linux mode, the v8 build process runs out of memory around step 450 of a d8 build, the message is ```internal compiler error: Killed (program cc1plus)```