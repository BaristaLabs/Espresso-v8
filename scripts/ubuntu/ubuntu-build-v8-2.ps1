# Powershell version of https://chromium.googlesource.com/chromium/src/+/master/docs/windows_build_instructions.md
# This script fetches v8
param (
    [string]$V8_VERSION = (&{If([string]::IsNullOrWhiteSpace($env:V8_VERSION)) {"7.4.288.25"} Else {$env:V8_VERSION}})
)

$PSCurrentPath = (Get-Location).Path

# Set Environment Variables
# Add depot tools to the path
$currentPath = $env:PATH
if (!($currentPath -match (":" + [regex]::Escape($PSCurrentPath) + "/depot_tools/$"))) {
    $env:PATH = $env:PATH + ":$PSCurrentPath/depot_tools/"
}
$env:PATH = $env:PATH -replace "~","$HOME"

$path = "$PSCurrentPath\v8"
# Fixes fetch error "LookupError: unknown encoding: cp65001"
$env:PYTHONIOENCODING = "UTF-8"

If(!(test-path $path)) {
    New-Item -ItemType Directory -Force -Path $path
    Set-Location $path
    Write-Output "Fetching V8 sources..."
    $start_time = Get-Date
    fetch --no-history v8
    Write-Output "Time taken: $((Get-Date).Subtract($start_time))"
}
Else {
    Set-Location $path
}

# Configure Git
git config --local core.autocrlf false
git config --local core.filemode false
git config --local branch.autosetupmerge always
git config --local branch.autosetuprebase always
# turn the detached message off
git config --local advice.detachedHead false

Set-Location "$path\v8"
Write-Output "Syncing V8 sources..."
$start_time = Get-Date
Write-Output "Using V8 Version $V8_VERSION"
# Redirect standard error messages to null
$env:GIT_REDIRECT_STDERR = '2>&1'
git fetch
git rebase-update
gclient sync -D
git checkout $V8_VERSION
Remove-Item env:GIT_REDIRECT_STDERR
Write-Output "Time taken: $((Get-Date).Subtract($start_time))"
Set-Location $PSCurrentPath

# Install additional build tools
Write-Output "Installing additional build tools..."
$start_time = Get-Date
./v8/v8/build/install-build-deps.sh
Write-Output "Time taken: $((Get-Date).Subtract($start_time))"