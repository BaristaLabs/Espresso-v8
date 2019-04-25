# Powershell version of https://chromium.googlesource.com/chromium/src/+/master/docs/windows_build_instructions.md
# This script generates the nuget packages.
param (
    [string]$CONFIGURATION = (&{If([string]::IsNullOrWhiteSpace($env:CONFIGURATION)) {"x64.release"} Else {$env:CONFIGURATION}})
)

$path = "$PSScriptRoot\nuget"
Set-Location $path

$PACKAGES = @('v8.win', 'v8.win-redist', 'v8.win-symbols')
$V8VersionParts = @('V8_MAJOR_VERSION', 'V8_MINOR_VERSION', 'V8_BUILD_NUMBER', 'V8_PATCH_LEVEL')

### Get v8 version from defines in v8-version.h
$V8Version = Get-Content "$PSScriptRoot\v8\v8\include\v8-version.h"

$version = @()

foreach($name in $V8VersionParts) {
	[regex]$rx = [regex]::new("#define\s+$name\s+(\d+)")
	$version += $rx.Match($V8Version).Groups[1].Value
}

# Set Environment Variables
# Add depot tools to the path
$env:Path = "$PSScriptRoot\depot_tools\;" + [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
$env:DEPOT_TOOLS_WIN_TOOLCHAIN = 0
$env:GYP_MSVS_VERSION=2019

$version = [string]::Join('.', $version)

foreach($name in $PACKAGES) {
	$nuspec = Get-Content "$PSScriptRoot\nuget\$name.nuspec" -Raw
	$nuspec = $nuspec.Replace('$Configuration$',$CONFIGURATION)
	$nuspec = $nuspec.Replace('$Version$',$version)
	$nuspecPath = "$PSScriptRoot\nuget\BaristaLabs.Espresso.$name-$CONFIGURATION.nuspec"
	Set-Content -Path $nuspecPath -Value $nuspec

	$props = Get-Content "$PSScriptRoot\nuget\$name.props" -Raw
	$props = $props.Replace('$Configuration$',$CONFIGURATION)
	$props = $props.Replace('$Version$',$version)
	$propsPath = "$PSScriptRoot\nuget\BaristaLabs.Espresso.$name-$CONFIGURATION.props"
	Set-Content -Path $propsPath -Value $props
	
	Write-Output "NuGet pack $name for V8 $CONFIGURATION $Version..."
	nuget pack "$nuspecPath" -NoPackageAnalysis -Version "$version" -OutputDirectory ".."
	Remove-Item -LiteralPath $nuspecPath
	Remove-Item -LiteralPath $propsPath
}

Set-Location $PSScriptRoot