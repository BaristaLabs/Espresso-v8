# Powershell version of https://chromium.googlesource.com/chromium/src/+/master/docs/windows_build_instructions.md
# This script fetches v8
param (
    [string]$V8_VERSION = (&{If([string]::IsNullOrWhiteSpace($env:V8_VERSION)) {"7.4.288.25"} Else {$env:V8_VERSION}})
)

$PSCurrentPath = (Get-Location).Path

# Set Environment Variables
# Add depot tools to the path
$currentPath = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
if (!($currentPath -match ("^" + [regex]::Escape($PSCurrentPath) + "\\depot_tools\\;"))) {
    $env:Path = "$PSCurrentPath\depot_tools\;" + $currentPath
    $currentPath = $env:Path
}
$env:DEPOT_TOOLS_WIN_TOOLCHAIN = 0
$env:GYP_MSVS_VERSION = 2019

$path = "$PSCurrentPath\v8"
# Fixes fetch error "LookupError: unknown encoding: cp65001"
$env:PYTHONIOENCODING = "UTF-8"

If(!(test-path $path)) {
    New-Item -ItemType Directory -Force -Path $path
    Set-Location $path
    Write-Output "Fetching V8 $V8_VERSION sources..."
    $start_time = Get-Date
    cmd.exe /C "fetch v8"
    Write-Output "Time taken: $((Get-Date).Subtract($start_time))"
}
Else {
    Set-Location $path
}

# Configure Git
git config --local core.autocrlf false
git config --local core.filemode false
# turn the detached message off
git config --local advice.detachedHead false

# Get the specified version.
Set-Location "$path\v8"
Write-Output "Syncing V8 $V8_VERSION sources..."
$start_time = Get-Date
Write-Output "Using V8 Version $V8_VERSION"
# Redirect standard error messages to null
$env:GIT_REDIRECT_STDERR = '2>&1'
cmd.exe /C "git checkout -b ci_branch_$V8_VERSION $V8_VERSION"
Remove-Item env:GIT_REDIRECT_STDERR
cmd.exe /C "gclient sync --delete_unversioned_trees"

Write-Output "Time taken: $((Get-Date).Subtract($start_time))"
Set-Location $PSCurrentPath