# Powershell version of https://chromium.googlesource.com/chromium/src/+/master/docs/windows_build_instructions.md
# This script downloads and installs any prerequisites 
$url = "https://storage.googleapis.com/chrome-infra/depot_tools.zip"
$output = "$PSScriptRoot\depot_tools.zip"

Write-Output "Downloading depot tools..."
$start_time = Get-Date
(New-Object System.Net.WebClient).DownloadFile($url, $output)
Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"

Write-Output "Expanding depot tools..."
Remove-Item -LiteralPath "$PSScriptRoot\depot_tools\" -Force -Recurse -ErrorAction SilentlyContinue
$start_time = Get-Date
Expand-Archive -LiteralPath "$PSScriptRoot\depot_tools.zip" -DestinationPath "$PSScriptRoot\depot_tools\"
Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"

# Set Environment Variables
# Add depot tools to the path
$env:Path = "$PSScriptRoot\depot_tools\;" + [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
$env:DEPOT_TOOLS_WIN_TOOLCHAIN = 0
$env:GYP_MSVS_VERSION=2019

# Install/Configure Tools
cmd.exe /c "gclient"
Where-Object python
git config --global user.name "My Name"
git config --global user.email "my-name@chromium.org"
git config --global core.autocrlf false
git config --global core.filemode false
git config --global branch.autosetupmerge always
git config --global branch.autosetuprebase always
