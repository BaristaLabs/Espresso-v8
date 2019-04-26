# Determines of a V8 Build needs to occur
$v8VersionTableUrl = "https://omahaproxy.appspot.com/all?csv=1"
$response = Invoke-WebRequest -Uri $v8VersionTableUrl -UseBasicParsing
$csv = ConvertFrom-CSV $response.content

$channel = "dev"
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

#Determine if there's a newer windows version.
try { 
    $response = Invoke-WebRequest -Uri "https://www.nuget.org/packages/BaristaLabs.Espresso.v8.win-x64.release/" -UseBasicParsing
    $options = [System.Text.RegularExpressions.RegexOptions]::Singleline
    [regex]$rx = [regex]::new("<title>.*?BaristaLabs.Espresso.v8.win-x64.release\s([\d+\.]+).*?</title>", $options)
    $publishedVersion = $rx.Match($response.content).Groups[1].Value

    if ($publishedVersion -lt $latestStableVersion_win) {
        Write-Output "Windows Build needed. Published: $publishedVersion, ${channel}: $latestStableVersion_win"
        $env:build_windows = 'true'
    } else {
        Write-Output "Windows Build not needed. Published: $publishedVersion, ${channel}: $latestStableVersion_win"
        $env:build_windows = 'false'
    }
} catch { 
    Write-Output "Unable to determine published Windows version"
    $env:build_windows = 'true'
}

#Determine if there's a newer macOS version.
try { 
    $response = Invoke-WebRequest -Uri "https://www.nuget.org/packages/BaristaLabs.Espresso.v8.macOS-x64.release/" -UseBasicParsing
    $options = [System.Text.RegularExpressions.RegexOptions]::Singleline
    [regex]$rx = [regex]::new("<title>.*?BaristaLabs.Espresso.v8.macOS-x64.release\s([\d+\.]+).*?</title>", $options)
    $publishedVersion = $rx.Match($response.content).Groups[1].Value

    if ($publishedVersion -lt $latestStableVersion_macOS) {
        Write-Output "macOS Build needed. Published: $publishedVersion, ${channel}: $latestStableVersion_macOS"
        
        $env:build_macOS = 'true'
    } else {
        Write-Output "macOS Build not needed. Published: $publishedVersion, ${channel}: $latestStableVersion_macOS"
        $env:build_macOS = 'false'
    }
} catch { 
    Write-Output "Unable to determine published macOS version"
    $env:build_macOS = 'true'
}

#Determine if there's a newer ubuntu version.
try { 
    $response = Invoke-WebRequest -Uri "https://www.nuget.org/packages/BaristaLabs.Espresso.v8.ubuntu-x64.release/" -UseBasicParsing
    $options = [System.Text.RegularExpressions.RegexOptions]::Singleline
    [regex]$rx = [regex]::new("<title>.*?BaristaLabs.Espresso.v8.ubuntu-x64.release\s([\d+\.]+).*?</title>", $options)
    $publishedVersion = $rx.Match($response.content).Groups[1].Value

    if ($publishedVersion -lt $latestStableVersion_linux) {
        Write-Output "Ubuntu Build needed. Published: $publishedVersion, ${channel}: $latestStableVersion_linux"
        $env:build_ubuntu = 'true'
    } else {
        Write-Output "Ubuntu Build not needed. Published: $publishedVersion, ${channel}: $latestStableVersion_linux"
        $env:build_ubuntu = 'false'
    }
} catch { 
    Write-Output "Unable to determine Published Ubuntu version"
    $env:build_ubuntu = 'true'
}

# set the multi-job variables
Write-Output "##vso[task.setvariable variable=V8_VERSION_WINDOWS;isOutput=true]$env:V8_VERSION_WINDOWS"
Write-Output "##vso[task.setvariable variable=build_windows;isOutput=true]$env:build_windows"

Write-Output "##vso[task.setvariable variable=V8_VERSION_MACOS;isOutput=true]$env:V8_VERSION_MACOS"
Write-Output "##vso[task.setvariable variable=build_macOS;isOutput=true]$env:build_macOS"

Write-Output "##vso[task.setvariable variable=V8_VERSION_UBUNTU;isOutput=true]$env:V8_VERSION_UBUNTU"
Write-Output "##vso[task.setvariable variable=build_ubuntu;isOutput=true]$env:build_ubuntu"