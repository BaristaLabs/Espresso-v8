# Powershell version of https://chromium.googlesource.com/chromium/src/+/master/docs/windows_build_instructions.md
# This script builds v8
param (
    [string]$CONFIGURATION = (&{If([string]::IsNullOrWhiteSpace($env:CONFIGURATION)) {"x64.release"} Else {$env:CONFIGURATION}})
)

# Set Environment Variables
# Add depot tools to the path
$currentPath = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
if ($currentPath -match ("^" + [regex]::Escape($PSScriptRoot) + "\\depot_tools\\;")) {
    $env:Path = "$PSScriptRoot\depot_tools\;" + $currentPath
}
$env:DEPOT_TOOLS_WIN_TOOLCHAIN = 0
$env:GYP_MSVS_VERSION=2019

$path = "$PSScriptRoot\v8\v8"
$GN_OPTIONS = @(
	'is_clang=false',
	'is_component_build=true',
	'use_custom_libcxx=false',
	'use_custom_libcxx_for_host=false',
	'v8_use_external_startup_data=true',
	'treat_warnings_as_errors=false',
    'use_jumbo_build=true',
    'enable_nacl=false',
	'blink_symbol_level=0',
	'symbol_level=1',
	'v8_enable_fast_mksnapshot=true'
)

Set-Location $path
# Fixes fetch error "LookupError: unknown encoding: cp65001"
$env:PYTHONIOENCODING = "UTF-8"

#Tip: Run "python tools\dev\v8gen.py list" to see a list of possible build configurations.
Write-Output "Generating build configuration for $CONFIGURATION..."
$start_time = Get-Date
python tools\dev\v8gen.py $CONFIGURATION
Add-Content "$path\out.gn\$CONFIGURATION\args.gn" ($GN_OPTIONS -join "`n")
Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"

#run gn gen
gn gen "$path\out.gn\$configuration"

Write-Output "Building $CONFIGURATION..."
$start_time = Get-Date
autoninja -C "$path\out.gn\$CONFIGURATION" d8
Write-Output "Time taken: $((Get-Date).Subtract($start_time))"

Set-Location $PSScriptRoot