# Powershell version of https://chromium.googlesource.com/chromium/src/+/master/docs/windows_build_instructions.md
# This script generates the nuget nuspec files.
param (
    [string]$CONFIGURATION = (&{If([string]::IsNullOrWhiteSpace($env:CONFIGURATION)) {"x64.release"} Else {$env:CONFIGURATION}})
)

$PSCurrentPath = (Get-Location).Path
$path = "$PSCurrentPath/nuget"
Set-Location $path

$PACKAGES = @('v8.ubuntu', 'v8.ubuntu-redist')
$V8VersionParts = @('V8_MAJOR_VERSION', 'V8_MINOR_VERSION', 'V8_BUILD_NUMBER', 'V8_PATCH_LEVEL')

### Get v8 version from defines in v8-version.h
$V8Version = Get-Content "$PSCurrentPath/v8/v8/include/v8-version.h"

$version = @()

foreach($name in $V8VersionParts) {
	[regex]$rx = [regex]::new("#define\s+$name\s+(\d+)")
	$version += $rx.Match($V8Version).Groups[1].Value
}
$version = [string]::Join('.', $version)

if(![string]::IsNullOrWhiteSpace($env:OVERRIDE_UBUNTU_VERSION)) {
	Write-Output "Overriding NuGet Version: Current Version: $version New Version: $env:OVERRIDE_UBUNTU_VERSION"
	$version = $env:OVERRIDE_UBUNTU_VERSION
}

foreach($name in $PACKAGES) {
	$nuspec = Get-Content "$PSCurrentPath/nuget/$name.nuspec" -Raw
	$nuspec = $nuspec.Replace('$Configuration$',$CONFIGURATION)
	$nuspec = $nuspec.Replace('$Version$',$version)
	$nuspecPath = "$PSCurrentPath/BaristaLabs.Espresso.$name-$CONFIGURATION.nuspec"
	Set-Content -Path $nuspecPath -Value $nuspec
}

Set-Location $PSCurrentPath