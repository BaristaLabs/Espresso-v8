# Determines of a V8 Build needs to occur
param (
    [string]$channel = (&{If([string]::IsNullOrWhiteSpace($env:V8_CHANNEL)) {"beta"} Else {$env:V8_CHANNEL}})
)

function Find-NugetPackageVersion {
    param (
        [string]$packageName,
        [string]$versionNumber
    )

    try { 
        $response = Invoke-WebRequest -Uri "https://www.nuget.org/packages/$packageName/" -UseBasicParsing
    } catch { 
        Write-Host "Unable to find nuget package $packageName version";
        return $false
    }

    $packageName = $packageName.Replace(".", "\.")
    $versionNumber = $versionNumber.Replace(".", "\.")

    $options = [System.Text.RegularExpressions.RegexOptions] "Singleline, IgnoreCase"
    [regex]$rx = [regex]::new("<a\s+href=""\/packages\/$packageName\/$versionNumber""\s+title=""$versionNumber"">.*?<\/a>", $options)
    return $rx.IsMatch($response.content)
}
function Get-BuildRequired {
    param (
        [string]$platform,
        [string]$packageName,
        [string]$versionNumber,
        [string]$versionEnv,
        [string]$forceEnv
    )

    [System.Environment]::SetEnvironmentVariable($versionEnv, $versionNumber);

    $forceVersion = [System.Environment]::GetEnvironmentVariable($forceEnv);
    if ((Find-NugetPackageVersion -packageName $packageName -versionNumber $versionNumber) -ne $true) {
        Write-Host "$platform Build needed for $versionNumber";
        return $true;
    } elseif(![string]::IsNullOrWhiteSpace($forceVersion)) {
        Write-Host "$platform Build forced ($forceVersion)";
        [System.Environment]::SetEnvironmentVariable($versionEnv, $forceVersion);
        return $true;
    } else {
        Write-Host "$platform Build not needed for $versionNumber";
        return $false;
    }
}

Write-Host "Using '$Channel' Channel."

# Get the current channel v8 build versions.
$v8VersionTableUrl = "https://omahaproxy.appspot.com/all?csv=1"
$response = Invoke-WebRequest -Uri $v8VersionTableUrl -UseBasicParsing
$csv = ConvertFrom-CSV $response.content

$win64Channel = $csv | Where-Object {$_.os -eq "win64" -and $_.channel -eq $channel} | Select-Object -First 1
$macOSChannel = $csv | Where-Object {$_.os -eq "mac" -and $_.channel -eq $channel} | Select-Object -First 1
$linuxChannel = $csv | Where-Object {$_.os -eq "linux" -and $_.channel -eq $channel} | Select-Object -First 1

if ($null -eq $win64Channel -or $null -eq $macOSChannel -or $null -eq $linuxChannel) {
    Write-Error "Unable to determine $channel version of v8"
    exit 1
}

# Determine if there are published versions that corresponds to the current channel version
$build_windows = Get-BuildRequired -platform "Windows" -packageName "BaristaLabs.Espresso.v8-monolith.win.x64.release" -versionNumber $win64Channel.v8_version -forceEnv "FORCE_WINDOWS" -versionEnv "V8_VERSION_WINDOWS"
$build_macOS = Get-BuildRequired -platform "macOS" -packageName "BaristaLabs.Espresso.v8-monolith.macOS.x64.release" -versionNumber $macOSChannel.v8_version -forceEnv "FORCE_MACOS" -versionEnv "V8_VERSION_MACOS"
$build_linux = Get-BuildRequired -platform "Linux" -packageName "BaristaLabs.Espresso.v8-monolith.linux.x64.release" -versionNumber $linuxChannel.v8_version -forceEnv "FORCE_LINUX" -versionEnv "V8_VERSION_LINUX"

# set the multi-job variables
Write-Output "##vso[task.setvariable variable=V8_VERSION_WINDOWS;isOutput=true]$env:V8_VERSION_WINDOWS"
Write-Output "##vso[task.setvariable variable=build_windows;isOutput=true]$build_windows"

Write-Output "##vso[task.setvariable variable=V8_VERSION_MACOS;isOutput=true]$env:V8_VERSION_MACOS"
Write-Output "##vso[task.setvariable variable=build_macOS;isOutput=true]$build_macOS"

Write-Output "##vso[task.setvariable variable=V8_VERSION_LINUX;isOutput=true]$env:V8_VERSION_LINUX"
Write-Output "##vso[task.setvariable variable=build_linux;isOutput=true]$build_linux"