<# : batch script
@echo off
setlocal
cd %~dp0
powershell -executionpolicy remotesigned -Command "Invoke-Expression $([System.IO.File]::ReadAllText('%~f0'))"
endlocal
goto:eof
#>

# Force TLS 1.2 to work with modern servers
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Path to the log file to keep a history
$logFilePath = Join-Path $env:USERPROFILE "Downloads\script_history.log"

# Function to display the menu with colors
function Show-Menu {
    Clear-Host
    Write-Host ""
    Write-Host "Options:" -ForegroundColor White
    Write-Host "1. " -NoNewline -ForegroundColor Cyan
    Write-Host "Enter a new URL" -ForegroundColor Blue
    Write-Host "2. " -NoNewline -ForegroundColor Cyan
    Write-Host "View history" -ForegroundColor Green
    Write-Host "3. " -NoNewline -ForegroundColor Cyan
    Write-Host "Clear history" -ForegroundColor Yellow
    Write-Host "4. " -NoNewline -ForegroundColor Cyan
    Write-Host "Exit (or type 'exit')" -ForegroundColor Red
}

# Main loop
while ($true) {
    Show-Menu
    $choice = Read-Host "Choose an option (1, 2, 3, 4, or type 'exit')"
    
    switch ($choice) {
        "1" {
            # Prompt the user to enter a source URL
            Write-Host "-------------------------------------------------------------------------------" -ForegroundColor Blue
            $sourceUrl = Read-Host "Enter the source URL (e.g., https://apps.apple.com/nl/app/safari/id1146562112)"
            $lookupUrlBase = "https://itunes.apple.com/lookup?id="
            
            # Extract the last 9 or 10 digits from the entered URL
            if ($sourceUrl -match "id(\d{9,10})") {
                $appId = $matches[1] # Extracted ID
                
                # Combine with the lookup URL base
                $lookupUrl = $lookupUrlBase + $appId
                Write-Host "Generated Lookup URL: $lookupUrl" -ForegroundColor Blue
                
                # Download the file
                $outputPath = Join-Path $env:USERPROFILE "Downloads\lookup_result.txt"
                Invoke-WebRequest -Uri $lookupUrl -OutFile $outputPath
                Write-Host "File downloaded to: $outputPath" -ForegroundColor Blue
                
                # Read the file content
                $fileContent = Get-Content $outputPath -Raw
                
                # Search for the "bundleId" value
                if ($fileContent -match '"bundleId":"([^"]+)"') {
                    $bundleId = $matches[1]
                    Write-Host "Found bundleId: $bundleId" -ForegroundColor Green
                } else {
                    $bundleId = "Could not find bundleId."
                    Write-Host $bundleId -ForegroundColor Red
                }
                
                # Log the input and output to the history file
                $logEntry = "Time: $(Get-Date) | Input: $sourceUrl | Generated URL: $lookupUrl | bundleId: " + 
                            $(if ($bundleId -eq "Could not find bundleId.") { 
                                $bundleId 
                            } else { 
                                $bundleId 
                            })
                Add-Content -Path $logFilePath -Value $logEntry
                Write-Host "History saved to: $logFilePath" -ForegroundColor Blue

                # Delete the temporary lookup_result.txt file
                Remove-Item $outputPath -Force
				Write-Host "Deleted the temporary lookup_result.txt file" -ForegroundColor Blue
				
                # Pause to allow user to read the output
                Write-Host "Press any key to continue..." -ForegroundColor Yellow
                $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
            } else {
                Write-Host "Could not find a valid ID in the entered URL." -ForegroundColor Red
                
                # Pause to allow user to read the output
                Write-Host "Press any key to continue..." -ForegroundColor Yellow
                $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
            }
        }
        "2" {
            # View history
            if (Test-Path $logFilePath) {
                Write-Host "History:" -ForegroundColor Green
                $historyContents = Get-Content $logFilePath
                foreach ($line in $historyContents) {
                    if ($line -match "Could not find bundleId\.") {
                        Write-Host $line -ForegroundColor Red
                    } else {
                        Write-Host $line -ForegroundColor DarkGreen 
                    }
                }
            } else {
                Write-Host "No history available." -ForegroundColor Red
            }
            
            # Pause to allow user to read the output
            Write-Host "Press any key to continue..." -ForegroundColor Yellow
            $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
        }
        "3" {
            # Clear history
            if (Test-Path $logFilePath) {
                Remove-Item $logFilePath -Force
                Write-Host "History has been cleared." -ForegroundColor Yellow
            } else {
                Write-Host "No history to clear." -ForegroundColor Red
            }
            
            # Pause to allow user to read the output
            Write-Host "Press any key to continue..." -ForegroundColor Yellow
            $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
        }
        "4" {
            Write-Host "Exiting script. Goodbye!" -ForegroundColor Red
            exit
        }
        "exit" {
            Write-Host "Exiting script. Goodbye!" -ForegroundColor Red
            exit
        }
        default {
            Write-Host "Invalid choice. Please try again." -ForegroundColor Red
            
            # Pause to allow user to read the output
            Write-Host "Press any key to continue..." -ForegroundColor Yellow
            $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
        }
    }
}

# Made by Chris or SUxpa2VMaWdodCBvbiBHaXRodWI= <-- Base64 :D
