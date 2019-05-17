# Determines of a V8 Build needs to occur
param (
    [string]$channel = (&{If([string]::IsNullOrWhiteSpace($env:V8_CHANNEL)) {"beta"} Else {$env:V8_CHANNEL}})
)

Write-Output "Using '$Channel' Channel."

$v8VersionTableUrl = "https://omahaproxy.appspot.com/all?csv=1"
$response = Invoke-WebRequest -Uri $v8VersionTableUrl -UseBasicParsing
$csv = ConvertFrom-CSV $response.content

function Find-NugetPackageVersion {
    param (
        [string]$packageName,
        [string]$versionNumber
    )

    try { 
        $response = Invoke-WebRequest -Uri "https://www.nuget.org/packages/$packageName/" -UseBasicParsing
    } catch { 
        Write-Output "Unable to find nuget package version"
        return $false
    }

    $packageName = $packageName.Replace(".", "\.")
    $versionNumber = $versionNumber.Replace(".", "\.")

    $options = [System.Text.RegularExpressions.RegexOptions] "Singleline, IgnoreCase"
    [regex]$rx = [regex]::new("<a\s+href=""\/packages\/$packageName\/$versionNumber""\s+title=""$versionNumber"">.*?<\/a>", $options)
    return !$rx.IsMatch($response.content)
}

$win64Stable = $csv | Where-Object {$_.os -eq "win64" -and $_.channel -eq $channel} | Select-Object -First 1
$macOSStable = $csv | Where-Object {$_.os -eq "mac" -and $_.channel -eq $channel} | Select-Object -First 1
$linuxStable = $csv | Where-Object {$_.os -eq "linux" -and $_.channel -eq $channel} | Select-Object -First 1

if ($null -eq $win64Stable -or $null -eq $macOSStable -or $null -eq $linuxStable) {
    Write-Error "Unable to determine $channel version of v8"
    exit 1
}

# Destructure and set variables from the latest channel v8 version numbers.
$latestStableVersion_win = $win64Stable.v8_version
$env:V8_VERSION_WINDOWS = $latestStableVersion_win

$latestStableVersion_macOS = $macOSStable.v8_version
$env:V8_VERSION_MACOS = $latestStableVersion_macOS

$latestStableVersion_linux = $linuxStable.v8_version
$env:V8_VERSION_UBUNTU = $latestStableVersion_linux

# Determine if there's a published windows version that corresponds to the current channel version
if (Find-NugetPackageVersion -packageName "BaristaLabs.Espresso.v8.win-x64.release" -versionNumber $latestStableVersion_win) {
    Write-Output "Windows Build needed for $latestStableVersion_win"
    $env:build_windows = 'true'
} elseif(![string]::IsNullOrWhiteSpace($env:FORCE_WINDOWS)) {
    Write-Output "Windows Build forced. Published: $publishedVersion, Forced: $env:FORCE_WINDOWS"
    $env:V8_VERSION_WINDOWS = $env:FORCE_WINDOWS
    $env:build_windows = 'true'
} else {
    Write-Output "Windows Build not needed for $latestStableVersion_win"
    $env:build_windows = 'false'
}

# Determine if there's a published macOS version that corresponds to the current channel version
if (Find-NugetPackageVersion -packageName "BaristaLabs.Espresso.v8.macOS-x64.release" -versionNumber $latestStableVersion_macOS) {
    Write-Output "macOS Build needed for $latestStableVersion_macOS"
    $env:build_macOS = 'true'
} elseif(![string]::IsNullOrWhiteSpace($env:FORCE_MACOS)) {
    Write-Output "macOS Build forced. Published: $publishedVersion, Forced: $env:FORCE_MACOS"
    $env:V8_VERSION_MACOS = $env:FORCE_MACOS
    $env:build_macOS = 'true'
} else {
    Write-Output "macOS Build not needed for $latestStableVersion_macOS"
    $env:build_macOS = 'false'
}

#Determine if there's a newer ubuntu version.
if (Find-NugetPackageVersion -packageName "BaristaLabs.Espresso.v8.ubuntu-x64.release" -versionNumber $latestStableVersion_linux) {
    Write-Output "Ubuntu Build needed for $latestStableVersion_linux"
    $env:build_ubuntu = 'true'
} elseif(![string]::IsNullOrWhiteSpace($env:FORCE_UBUNTU)) {
    Write-Output "Ubuntu Build forced. Published: $publishedVersion, Forced: $env:FORCE_UBUNTU"
    $env:V8_VERSION_UBUNTU = $env:FORCE_UBUNTU
    $env:build_ubuntu = 'true'
} else {
    Write-Output "Ubuntu Build not needed for $latestStableVersion_linux"
    $env:build_ubuntu = 'false'
}

# set the multi-job variables
Write-Output "##vso[task.setvariable variable=V8_VERSION_WINDOWS;isOutput=true]$env:V8_VERSION_WINDOWS"
Write-Output "##vso[task.setvariable variable=build_windows;isOutput=true]$env:build_windows"

Write-Output "##vso[task.setvariable variable=V8_VERSION_MACOS;isOutput=true]$env:V8_VERSION_MACOS"
Write-Output "##vso[task.setvariable variable=build_macOS;isOutput=true]$env:build_macOS"

Write-Output "##vso[task.setvariable variable=V8_VERSION_UBUNTU;isOutput=true]$env:V8_VERSION_UBUNTU"
Write-Output "##vso[task.setvariable variable=build_ubuntu;isOutput=true]$env:build_ubuntu"