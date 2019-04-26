# Espresso-v8
---

This package contains scripts and configuration to perform automated multi-platform V8 Builds using Azure DevOps and publish the resulting binaries to NuGet. These pre-built V8 libraries and headers then can be used to embed the V8 JavaScript engine into multi-platform C++ projects.

> Note: This repository contains dynamic and static V8 builds targeting win-VS2019, macOS, and Ubuntu using a different set of GN_Options used for BaristaLabs.Espresso. See [this repository](https://github.com/pmed/v8-nuget) for different platform toolsets.

| Package                     | Version
|-----------------------------|----------------------------------------------------------------------------------------------------------------------|
|V8 Windows x86 for Visual Studio 2019|[![NuGet](https://img.shields.io/nuget/v/BaristaLabs.Espresso.v8.win-ia32.release.svg)](https://www.nuget.org/packages/BaristaLabs.Espresso.v8.win-ia32.release/)|
|V8 Windows x64 for Visual Studio 2019|[![NuGet](https://img.shields.io/nuget/v/BaristaLabs.Espresso.v8.win-x64.release.svg)](https://www.nuget.org/packages/BaristaLabs.Espresso.v8.win-x64.release/)|
|V8 Static x64 for Visual Studio 2019|[![NuGet](https://img.shields.io/nuget/v/BaristaLabs.Espresso.v8-static.win-x64.svg)](https://www.nuget.org/packages/BaristaLabs.Espresso.v8-static.win-x64/)|
|V8 macOS x64|[![NuGet](https://img.shields.io/nuget/v/BaristaLabs.Espresso.v8.macOS-x64.release.svg)](https://www.nuget.org/packages/BaristaLabs.Espresso.v8.macOS-x64.release/)|
|V8 Ubuntu x64|[![NuGet](https://img.shields.io/nuget/v/BaristaLabs.Espresso.v8.ubuntu-x64.release.svg)](https://www.nuget.org/packages/BaristaLabs.Espresso.v8.ubuntu-x64.release/)|

## Usage

Most people who find this project want to simply embed the pre-built v8 binaries from nuget mentioned above into a C++ project.

To use V8 in a project install the package `BaristaLabs.Espresso.v8.win-$Configuration.$Version`
from a console with `nuget install` command or from inside of Visual Studio
(see menu option *Tools -> NuGet Package Manager -> Manage NuGet Packages for Solution...*)
where

  * `$Configuration` is a target v8 pre-defined configuration, such as `ia32.release` or `x64.release`.

  * `$Version` is the actual V8 version, one of https://chromium.googlesource.com/v8/v8.git/+refs

After successful packages installation add `#include <v8.h>` in a C++ project
and build it. In Visual Studio 2019, all necessary files (*.lib, *.dll, *.pdb) would be referenced
in the project automatically with MsBuild property sheets.

This is not currently true for macOS and Ubuntu using Visual Studio for Mac or other IDEs.

## How to build and publish in Azure Devops

Simply fork this repo, reference it in Azure Devops project, create a new YAML build pipeline, select the azure-pipelines.yml file from this repo and queue a build.

The included pipeline will check for the latest version of v8 against the nuget package name and build, pack and push a new nuget package if outdated. The author of this project uses a nightly trigger to check for new, stable v8 releases and automatically publish new builds.

Consumers of this project might want to change the package name or publish to a private nuget feed, those exercises are left to the reader.

## How to build and publish in a local dev environment

Ensure that build dependencies have been are installed in the approprate environments.

See the following for a reference: https://v8.dev/docs/build

Also, in windows, install the Windows 10 SDK separately from Visual Studio 2019: https://developer.microsoft.com/en-US/windows/downloads/windows-10-sdk
   
Ensure the Debugging tools are installed as it is required.

To build V8 and make NuGet packages:

Simply run through the powershell scripts sequentially for the target environment.
Use the azure-pipelines.yml as a guide for the inputs.

Once the 4 scripts have been run, package/push using NuGet.

> Note: Visit https://omahaproxy.appspot.com/ for a list of the V8 versions that correspond to a Chrome build.
