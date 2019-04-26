# Powershell version of https://chromium.googlesource.com/chromium/src/+/master/docs/windows_build_instructions.md
# This script builds v8
param (
    [string]$CONFIGURATION = (&{If([string]::IsNullOrWhiteSpace($env:CONFIGURATION)) {"x64.release"} Else {$env:CONFIGURATION}})
)

$PSCurrentPath = (Get-Location).Path

# Set Environment Variables
# Add depot tools to the path
$currentPath = $env:PATH
if (!($currentPath -match (":" + [regex]::Escape($PSCurrentPath) + "/depot_tools/$"))) {
    $env:PATH = $env:PATH + ":$PSCurrentPath/depot_tools/"
}
$env:PATH = $env:PATH -replace "~","$HOME"

$path = "$PSCurrentPath/v8/v8"
$GN_OPTIONS = @(
	'is_clang=false',
	'is_component_build=true',
	'use_custom_libcxx=false',
	'use_custom_libcxx_for_host=false',
	'v8_use_external_startup_data=true',
	'treat_warnings_as_errors=false',
    'use_jumbo_build=true',
    'enable_nacl=false',
	'symbol_level=1',
	'v8_enable_fast_mksnapshot=true'
)

Set-Location $path
xcode-select --print-path

#Tip: Run "python tools/dev/v8gen.py list" to see a list of possible build configurations.
$argsPath = "$path/out.gn/$CONFIGURATION/args.gn"
Write-Output "Generating build configuration for $CONFIGURATION to $argsPath..."
$start_time = Get-Date
python tools/dev/v8gen.py $CONFIGURATION
Add-Content $argsPath ($GN_OPTIONS -join "`n")
Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"

#run gn gen
gn gen "$path/out.gn/$configuration"

Write-Output "Building $CONFIGURATION..."
$start_time = Get-Date
autoninja -C "$path/out.gn/$CONFIGURATION" d8
Write-Output "Time taken: $((Get-Date).Subtract($start_time))"

Set-Location $PSCurrentPath