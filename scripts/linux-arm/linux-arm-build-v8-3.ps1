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
# Tip: Run "cmd /C "gn args --list ""$path\out.gn\$CONFIGURATION""" > options.txt" to list all options
$GN_OPTIONS = @(
	'v8_target_cpu = "arm64"',

	'is_cfi = false',
	'is_debug = false',
	'is_component_build = false',
	'use_gold = false',
	'use_goma = false',
	'goma_dir = "None"',
	
	'symbol_level = 0',
	'strip_debug_info = true',
	'treat_warnings_as_errors = false',
	
	'is_clang = false',
	'v8_monolithic = true',
	'v8_use_external_startup_data = false',
	'v8_enable_i18n_support = false',
		
	'v8_enable_fast_mksnapshot = true',
	'v8_enable_backtrace = true',
	'v8_enable_disassembler = true',
	'v8_enable_object_print = true',
	'v8_enable_verify_heap = true',
	"v8_untrusted_code_mitigations = false"
)

Set-Location $path

# Tip: Run "python tools/dev/v8gen.py list" to see a list of possible build configurations.
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
# Tip: Run "autoninja -C "$path/out.gn/$CONFIGURATION" -t targets all > output.txt" to list all targets
autoninja -C "$path/out.gn/$CONFIGURATION" v8_monolith
Write-Output "Time taken: $((Get-Date).Subtract($start_time))"

Set-Location $PSCurrentPath
