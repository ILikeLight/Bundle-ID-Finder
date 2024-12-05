<# : batch script
@echo off
setlocal
cd %~dp0
powershell -executionpolicy remotesigned -Command "Invoke-Expression $([System.IO.File]::ReadAllText('%~f0'))"
endlocal
goto:eof
#>

# Past this point its only Powershell code

# Force TLS 1.2 to work with modern servers
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Path to the log file to keep a history
$logFilePath = Join-Path $env:USERPROFILE "Downloads\script_history.log"

# Display options: View history or clear history
Write-Output "Options:"
Write-Output "1. Enter a new URL."
Write-Output "2. View history."
Write-Output "3. Clear history."
$choice = Read-Host "Choose an option (1, 2, or 3)"

switch ($choice) {
    1 {
        # Prompt the user to enter a source URL
        $sourceUrl = Read-Host "Enter the source URL (e.g., https://apps.apple.com/nl/app/safari/id1146562112)"
        $lookupUrlBase = "https://itunes.apple.com/lookup?id="

        # Extract the last 9 or 10 digits from the entered URL
        if ($sourceUrl -match "id(\d{9,10})") {
            $appId = $matches[1] # Extracted ID
            # Combine with the lookup URL base
            $lookupUrl = $lookupUrlBase + $appId
            Write-Output "Generated Lookup URL: $lookupUrl"
            
            # Download the file
            $outputPath = Join-Path $env:USERPROFILE "Downloads\lookup_result.txt"
            Invoke-WebRequest -Uri $lookupUrl -OutFile $outputPath
            Write-Output "File downloaded to: $outputPath"

            # Read the file content
            $fileContent = Get-Content $outputPath -Raw

            # Search for the "bundleId" value
            if ($fileContent -match '"bundleId":"([^"]+)"') {
                $bundleId = $matches[1]
                Write-Output "Found bundleId: $bundleId"
            } else {
                $bundleId = "Could not find bundleId."
                Write-Output $bundleId
            }

            # Log the input and output to the history file
            $logEntry = "Time: $(Get-Date) | Input: $sourceUrl | Generated URL: $lookupUrl | bundleId: $bundleId"
            Add-Content -Path $logFilePath -Value $logEntry
            Write-Output "History saved to: $logFilePath"
            
        } else {
            Write-Output "Could not find a valid ID in the entered URL."
        }
    }
    2 {
        # View history
        if (Test-Path $logFilePath) {
            Write-Output "History:"
            Get-Content $logFilePath
        } else {
            Write-Output "No history available."
        }
    }
    3 {
        # Clear history
        if (Test-Path $logFilePath) {
            Remove-Item $logFilePath -Force
            Write-Output "History has been cleared."
        } else {
            Write-Output "No history to clear."
        }
    }
    default {
        Write-Output "Invalid choice. Please restart the script and try again."
    }
}

# Pause to keep the window open
Write-Host "Script execution complete. Press any key to exit." -ForegroundColor Yellow
pause

# Made by Chris or SUxpa2VMaWdodCBvbiBHaXRodWI= <-- Base64 :D
