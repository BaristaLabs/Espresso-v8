# Powershell version of https://chromium.googlesource.com/chromium/src/+/master/docs/windows_build_instructions.md
# This script builds v8
param (
	[string]$CONFIGURATION = (& { If ([string]::IsNullOrWhiteSpace($env:CONFIGURATION)) { "arm64.release" } Else { $env:CONFIGURATION } })
)

$PSCurrentPath = (Get-Location).Path

# Set Environment Variables
# Add depot tools to the path
$currentPath = $env:PATH
if (!($currentPath -match (":" + [regex]::Escape($PSCurrentPath) + "/depot_tools/$"))) {
	$env:PATH = $env:PATH + ":$PSCurrentPath/depot_tools/"
}
$env:PATH = $env:PATH -replace "~", "$HOME"

$path = "$PSCurrentPath/v8/v8"
$GN_OPTIONS = @(
	'target_cpu = "arm64"',
	'v8_target_cpu = "arm64"',
	'is_clang=false',
	'v8_monolithic=true',
	'v8_use_external_startup_data=false',
	'treat_warnings_as_errors=false',
	'symbol_level=1',
	'v8_enable_fast_mksnapshot=true'
)

Set-Location $path

#Tip: Run "python tools/dev/v8gen.py list" to see a list of possible build configurations.
$argsPath = "$path/out.gn/$CONFIGURATION/args.gn"
Write-Output "Generating build configuration for $CONFIGURATION to $argsPath..."
$start_time = Get-Date
python tools/dev/v8gen.py $CONFIGURATION
Add-Content $argsPath ($GN_OPTIONS -join "`n")
Write-Output "Time taken: $((Get-Date).Subtract($start_time).TotalSeconds) second(s)"

#run gn gen
gn gen "$path/out.gn/$CONFIGURATION"

Write-Output "Building $CONFIGURATION..."
$start_time = Get-Date
autoninja -C "$path/out.gn/$CONFIGURATION" v8_monolith
Write-Output "Time taken: $((Get-Date).Subtract($start_time))"

Set-Location $PSCurrentPath
