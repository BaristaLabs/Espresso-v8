# Powershell version of https://chromium.googlesource.com/chromium/src/+/master/docs/windows_build_instructions.md
# This script downloads and installs any prerequisites 
$url = "https://chromium.googlesource.com/chromium/tools/depot_tools.git"
$PSCurrentPath = (Get-Location).Path

Write-Output "Cloning depot tools..."
$start_time = Get-Date
git clone $url "$PSCurrentPath/depot_tools"
Write-Output "Time taken: $((Get-Date).Subtract($start_time).TotalSeconds) second(s)"

#touch a metrics.cfg file to supress a warning when invoking gclient
$metrics = '{"is-googler": false, "countdown": 10, "version": 1, "opt-in": null}'
Set-Content -Path "$PSCurrentPath/depot_tools/metrics.cfg" -Value $metrics

# Set Environment Variables
# Add depot tools to the path
$env:PATH = $env:PATH + ":$PSCurrentPath/depot_tools/"
$env:PATH = $env:PATH -replace "~","$HOME"

# Install/Configure Tools
Write-Output "Invoking gclient..."
$start_time = Get-Date
gclient
Write-Output "Time taken: $((Get-Date).Subtract($start_time))"
