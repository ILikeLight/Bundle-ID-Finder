<# : batch script
@echo off
setlocal
cd %~dp0
powershell -executionpolicy remotesigned -Command "Invoke-Expression $([System.IO.File]::ReadAllText('%~f0'))"
endlocal
goto:eof
#>

# Script for retrieving bundleId from Apple App Store URLs

# Force TLS 1.2 for compatibility with modern servers
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Configuration settings
$configSettings = @{
    LogFilePath = Join-Path $env:USERPROFILE "Downloads\script_history.log"
    LookupUrlBase = "https://itunes.apple.com/lookup?id="
    TemporaryResultFile = Join-Path $env:USERPROFILE "Downloads\lookup_result.txt"
}

# Function for displaying the menu with colors
function Show-MainMenu {
    Clear-Host
    
    Write-Host "Apple App Store Bundle ID Lookup Utility" -ForegroundColor Cyan
    Write-Host "=======================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Available options:" -ForegroundColor White
    
    $menuOptions = @{
        "1" = @{ Text = "Enter a new URL"; Color = "Blue" }
        "2" = @{ Text = "View history"; Color = "Green" }
        "3" = @{ Text = "Clear history"; Color = "Yellow" }
        "4" = @{ Text = "Exit application"; Color = "Red" }
    }
    
    foreach ($key in $menuOptions.Keys) {
        Write-Host "$key. " -NoNewline -ForegroundColor Cyan
        Write-Host $menuOptions[$key].Text -ForegroundColor ($menuOptions[$key].Color)
    }
    
    Write-Host ""
    Write-Host "Type 'exit' to close the script" -ForegroundColor DarkGray
}

# Function for validating the URL
function Test-AppStoreUrl {
    param (
        [string]$Url
    )
    
    return $Url -match "id(\d{9,10})"
}

# Function for retrieving the bundleId
function Get-AppBundleId {
    param (
        [string]$Url,
        [string]$LookupUrlBase,
        [string]$OutputPath
    )
    
    # If the URL is valid, extract the app ID
    if ($Url -match "id(\d{9,10})") {
        $appId = $matches[1]
        $lookupUrl = $LookupUrlBase + $appId
        
        Write-Host "Generated Lookup URL: $lookupUrl" -ForegroundColor Blue
        
        try {
            # Download the lookup results
            Invoke-WebRequest -Uri $lookupUrl -OutFile $OutputPath
            
            # Read the file content
            $fileContent = Get-Content $OutputPath -Raw
            
            # Search for the bundleId
            if ($fileContent -match '"bundleId":"([^"]+)"') {
                $bundleId = $matches[1]
                Write-Host "Found bundleId: $bundleId" -ForegroundColor Green
                return $bundleId
            }
            else {
                Write-Host "No bundleId found." -ForegroundColor Red
                return "Could not find bundleId."
            }
        }
        catch {
            Write-Host "Error retrieving data: $_" -ForegroundColor Red
            return "Error retrieving data"
        }
    }
    else {
        Write-Host "Invalid URL: No app ID found" -ForegroundColor Red
        return $null
    }
}

# Function for logging activities
function Add-ActivityToLog {
    param (
        [string]$LogPath,
        [string]$SourceUrl,
        [string]$LookupUrl,
        [string]$BundleId
    )
    
    $logEntry = "Timestamp: $(Get-Date) | Source URL: $SourceUrl | Lookup URL: $LookupUrl | Bundle ID: $BundleId"
    Add-Content -Path $LogPath -Value $logEntry
    
    Write-Host "History saved successfully" -ForegroundColor Blue
}

# Function for viewing history
function Show-History {
    param (
        [string]$LogPath
    )
    
    if (Test-Path $LogPath) {
        Write-Host "History:" -ForegroundColor Green
        $historyContents = Get-Content $LogPath
        
        foreach ($line in $historyContents) {
            if ($line -match "Could not find bundleId\.") {
                Write-Host $line -ForegroundColor Red
            }
            else {
                Write-Host $line -ForegroundColor DarkGreen
            }
        }
    }
    else {
        Write-Host "No history available." -ForegroundColor Red
    }
}

# Function for clearing history
function Clear-ActivityHistory {
    param (
        [string]$LogPath
    )
    
    if (Test-Path $LogPath) {
        Remove-Item $LogPath -Force
        Write-Host "History has been cleared." -ForegroundColor Yellow
    }
    else {
        Write-Host "No history to clear." -ForegroundColor Red
    }
}

# Main script logic
function Invoke-MainScript {
    while ($true) {
        Show-MainMenu
        
        $choice = Read-Host "Make your choice (1, 2, 3, 4, or type 'exit')"
        
        switch ($choice) {
            "1" {
                $sourceUrl = Read-Host "Enter the source URL (e.g., https://apps.apple.com/nl/app/safari/id1146562112)"
                
                $bundleId = Get-AppBundleId `
                    -Url $sourceUrl `
                    -LookupUrlBase $configSettings.LookupUrlBase `
                    -OutputPath $configSettings.TemporaryResultFile
                
                if ($bundleId) {
                    Add-ActivityToLog `
                        -LogPath $configSettings.LogFilePath `
                        -SourceUrl $sourceUrl `
                        -LookupUrl ($configSettings.LookupUrlBase + ($sourceUrl -replace '^.*?id(\d+).*$','$1')) `
                        -BundleId $bundleId
                    
                    # Remove temporary file
                    Remove-Item $configSettings.TemporaryResultFile -Force
                }
                
                Write-Host "Press any key to continue..." -ForegroundColor Yellow
                $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
            }
            "2" {
                Show-History -LogPath $configSettings.LogFilePath
                
                Write-Host "Press any key to continue..." -ForegroundColor Yellow
                $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
            }
            "3" {
                Clear-ActivityHistory -LogPath $configSettings.LogFilePath
                
                Write-Host "Press any key to continue..." -ForegroundColor Yellow
                $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
            }
            "4" { 
                Write-Host "Closing script. Goodbye!" -ForegroundColor Red
                exit 
            }
            "exit" { 
                Write-Host "Closing script. Goodbye!" -ForegroundColor Red
                exit 
            }
            default {
                Write-Host "Invalid choice. Please try again." -ForegroundColor Red
                
                Write-Host "Press any key to continue..." -ForegroundColor Yellow
                $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
            }
        }
    }
}

# Start the script
Invoke-MainScript
# Made by Chris or SUxpa2VMaWdodCBvbiBHaXRodWI= <-- Base64 :D