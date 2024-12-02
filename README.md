[#💾 Download script](https://github.com/ILikeLight/Bundle-ID-Finder/blob/main/Bundle%20id%20generator.cmd)

    <# : batch script
    @echo off
    setlocal
    cd %~dp0
    powershell -executionpolicy remotesigned -Command "Invoke-Expression $([System.IO.File]::ReadAllText('%~f0'))"
    endlocal
    goto:eof
    #>

# Past this point its only Powershell code

# Force TLS 1.2 To make a connection to a modern server
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Ask user to input a url
    $sourceUrl = Read-Host "Input Source URL (Example: https://apps.apple.com/nl/app/safari/id1146562112)"
    $lookupUrlBase = "https://itunes.apple.com/lookup?id="

# Extract the last 9 or 10 numbers from the url
    if ($sourceUrl -match "id(\d{9,10})") {
    $appId = $matches[1] # The ID gets taken from this
    # Combine with the lookup-URL
    $lookupUrl = $lookupUrlBase + $appId
    Write-Output "Generated Lookup URL: $lookupUrl"
    
# Download the file
    $outputPath = Join-Path $env:USERPROFILE "Downloads\lookup_result.txt"
    Invoke-WebRequest -Uri $lookupUrl -OutFile $outputPath
    Write-Output "File Downloaded to: $outputPath"

 # Read the contents of the file
    $fileContent = Get-Content $outputPath -Raw

 # Search for the value "bundleId"
    if ($fileContent -match '"bundleId":"([^"]+)"') {
        $bundleId = $matches[1]
        Write-Output "Found bundleId: $bundleId"
    } else {
        Write-Output "Could not find a bundleID in the file."
	# Pauze to keep window open
        Read-Host "Press ENTER to close the window"
    }
    
    } else {
    Write-Output "Could not find a valid id in the enterd url."
	# Pauze to keep window open
    Read-Host "Press ENTER to close the window"
    }

# Pauze to keep window open
    Read-Host "Press ENTER to close the window"


# Made by Chris or SUxpa2VMaWdodCBvbiBHaXRodWI= <-- Base64 :D
