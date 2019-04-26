# Powershell version of https://chromium.googlesource.com/chromium/src/+/master/docs/windows_build_instructions.md
# This script generates the nuget nuspec files.
param (
	[string]$CONFIGURATION = (&{If([string]::IsNullOrWhiteSpace($env:CONFIGURATION)) {"x64.release"} Else {$env:CONFIGURATION}}),
	[string]$STATIC = (&{If([string]::IsNullOrWhiteSpace($env:STATIC)) {"false"} Else {$env:STATIC}})
)

$PSCurrentPath = (Get-Location).Path
$path = "$PSCurrentPath\nuget"
Set-Location $path

$PACKAGES = @('v8.win', 'v8.win-redist', 'v8.win-symbols')
if ($STATIC -eq "true") {
	$PACKAGES = @('v8-static.win')
}

$V8VersionParts = @('V8_MAJOR_VERSION', 'V8_MINOR_VERSION', 'V8_BUILD_NUMBER', 'V8_PATCH_LEVEL')

### Get v8 version from defines in v8-version.h
$V8Version = Get-Content "$PSCurrentPath\v8\v8\include\v8-version.h"

$version = @()

foreach($name in $V8VersionParts) {
	[regex]$rx = [regex]::new("#define\s+$name\s+(\d+)")
	$version += $rx.Match($V8Version).Groups[1].Value
}
$version = [string]::Join('.', $version)

$configParts = $CONFIGURATION.Split(".")
$arch = $configParts[0]
$config = $configParts[1]

if ($arch -eq "ia32") {
	$platform = "('`$(Platform)' == 'x86' Or '`$(Platform)' == 'Win32')"
} else {
	$platform = "'`$(Platform)' == '$arch'"
}

#Config is currently unused in the condition
if ($config -eq "release") {
	$config = "'`$(Configuration)' == 'Release'"
} elseif ($config -eq "debug") {
	$config = "'`$(Configuration)' == 'Debug'"
}

$condition = "'`$(PlatformToolset)' == 'v142' And $platform"

foreach($name in $PACKAGES) {
	$nuspec = Get-Content "$PSCurrentPath\nuget\$name.nuspec" -Raw
	$nuspec = $nuspec.Replace('$Configuration$',$CONFIGURATION)
	$nuspec = $nuspec.Replace('$Version$',$version)
	$nuspecPath = "$PSCurrentPath\BaristaLabs.Espresso.$name-$CONFIGURATION.nuspec"
	Set-Content -Path $nuspecPath -Value $nuspec

	$props = Get-Content "$PSCurrentPath\nuget\$name.props" -Raw
	$props = $props.Replace('$Configuration$',$CONFIGURATION)
	$props = $props.Replace('$Version$',$version)
	$props = $props.Replace('$Condition$',$condition)
	$propsPath = "$PSCurrentPath\BaristaLabs.Espresso.$name-$CONFIGURATION.props"
	Set-Content -Path $propsPath -Value $props
}

Set-Location $PSCurrentPath