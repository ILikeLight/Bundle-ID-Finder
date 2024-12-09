<# : batch script
@echo off
setlocal
cd %~dp0
powershell -executionpolicy remotesigned -Command "Invoke-Expression $([System.IO.File]::ReadAllText('%~f0'))"
endlocal
goto:eof
#>

<#
.SYNOPSIS
    Apple App Store Bundle ID Retriever with History
.DESCRIPTION
    This script extracts bundle IDs from Apple App Store links and maintains a history of lookups.
.AUTHOR
    CodingFleet
.VERSION
    1.0.0
#>

# Function to display fancy banner
function Show-Banner {
    Clear-Host
    Write-Host "`n===============================================" -ForegroundColor Cyan
    Write-Host "     🍎 Apple Store Bundle ID Retriever 🔍" -ForegroundColor Yellow
    Write-Host "===============================================`n" -ForegroundColor Cyan
}

# Function to create or verify history file
function Initialize-HistoryFile {
    $script:historyPath = Join-Path $env:USERPROFILE "AppStoreLookupHistory.txt"
    if (-not (Test-Path $historyPath)) {
        @{
            "LastUpdated" = (Get-Date).ToString()
            "Lookups" = @()
        } | ConvertTo-Json | Set-Content $historyPath
        Write-Host "✨ History file created at: $historyPath`n" -ForegroundColor Green
    }
}

# Function to add entry to history
function Add-ToHistory {
    param (
        [string]$AppStoreUrl,
        [string]$BundleId,
        [string]$AppName
    )
    
    $history = Get-Content $historyPath | ConvertFrom-Json
    $newEntry = @{
        "Timestamp" = (Get-Date).ToString()
        "AppStoreUrl" = $AppStoreUrl
        "BundleId" = $BundleId
        "AppName" = $AppName
    }
    
    $history.Lookups += $newEntry
    $history.LastUpdated = (Get-Date).ToString()
    $history | ConvertTo-Json -Depth 10 | Set-Content $historyPath
}

# Function to display history
function Show-History {
    $history = Get-Content $historyPath | ConvertFrom-Json
    
    if ($history.Lookups.Count -eq 0) {
        Write-Host "📝 No lookup history found.`n" -ForegroundColor Yellow
        return
    }

    Write-Host "`n📜 Lookup History:" -ForegroundColor Cyan
    Write-Host "===================" -ForegroundColor Cyan
    
    foreach ($entry in $history.Lookups) {
        Write-Host "`nTimestamp: " -NoNewline -ForegroundColor Yellow
        Write-Host $entry.Timestamp
        Write-Host "App Name: " -NoNewline -ForegroundColor Yellow
        Write-Host $entry.AppName
        Write-Host "Bundle ID: " -NoNewline -ForegroundColor Yellow
        Write-Host $entry.BundleId
        Write-Host "URL: " -NoNewline -ForegroundColor Yellow
        Write-Host $entry.AppStoreUrl
        Write-Host "-------------------" -ForegroundColor DarkGray
    }
}

# Function to extract App ID from URL
function Get-AppId {
    param ([string]$url)
    
    if ($url -match "id(\d+)") {
        return $matches[1]
    }
    return $null
}

# Function to get bundle ID from iTunes API
function Get-BundleId {
    param ([string]$appId)
    
    try {
        $apiUrl = "https://itunes.apple.com/lookup?id=$appId"
        $response = Invoke-RestMethod -Uri $apiUrl -Method Get
        
        if ($response.resultCount -eq 0) {
            throw "No results found for the given App ID"
        }
        
        $bundleId = $response.results[0].bundleId
        $appName = $response.results[0].trackName
        
        return @{
            BundleId = $bundleId
            AppName = $appName
        }
    }
    catch {
        Write-Host "❌ Error: $_" -ForegroundColor Red
        return $null
    }
}

# Function to validate URL
function Test-AppStoreUrl {
    param ([string]$url)
    
    return $url -match "^https?://apps\.apple\.com/.+/app/.+/id\d+$"
}

# Main menu function
function Show-Menu {
    Write-Host "Please select an option:" -ForegroundColor Yellow
    Write-Host "1. " -NoNewline -ForegroundColor Cyan
    Write-Host "Look up Bundle ID"
    Write-Host "2. " -NoNewline -ForegroundColor Cyan
    Write-Host "View History"
    Write-Host "3. " -NoNewline -ForegroundColor Cyan
    Write-Host "Clear History"
    Write-Host "4. " -NoNewline -ForegroundColor Cyan
    Write-Host "Exit"
	Write-Host ""
    Write-Host "You can also type 'exit'" -ForegroundColor DarkGray
    Write-Host "Enter your choice (1-4): " -NoNewline -ForegroundColor Yellow
}

# Main script execution
try {
    Initialize-HistoryFile
    
    do {
        Show-Banner
        Show-Menu
        $choice = Read-Host
        
        switch ($choice) {
            "1" {
                Write-Host "`nEnter Apple Store URL: " -NoNewline -ForegroundColor Yellow
                $url = Read-Host
                
                if (-not (Test-AppStoreUrl $url)) {
                    Write-Host "`n❌ Invalid Apple Store URL format!`n" -ForegroundColor Red
                    pause
                    continue
                }
                
                Write-Host "`n🔍 Processing..." -ForegroundColor Cyan
                
                $appId = Get-AppId $url
                if ($null -eq $appId) {
                    Write-Host "❌ Could not extract App ID from URL!`n" -ForegroundColor Red
                    pause
                    continue
                }
                
                $result = Get-BundleId $appId
                if ($null -ne $result) {
                    Write-Host "`n✅ Results:" -ForegroundColor Green
                    Write-Host "App Name: " -NoNewline -ForegroundColor Yellow
                    Write-Host $result.AppName
                    Write-Host "Bundle ID: " -NoNewline -ForegroundColor Yellow
                    Write-Host $result.BundleId
                    
                    Add-ToHistory -AppStoreUrl $url -BundleId $result.BundleId -AppName $result.AppName
                }
                Write-Host "`n"
                pause
            }
            "2" {
                Show-History
                Write-Host "`n"
                pause
            }
            "3" {
                @{
                    "LastUpdated" = (Get-Date).ToString()
                    "Lookups" = @()
                } | ConvertTo-Json | Set-Content $historyPath
                Write-Host "`n✨ History cleared successfully!`n" -ForegroundColor Green
                pause
            }
            "4" {
                Write-Host "`n👋 Goodbye!" -ForegroundColor Cyan
                exit
            }
            default {
                Write-Host "`n❌ Invalid choice! Please select 1-4.`n" -ForegroundColor Red
                pause
            }
        }
    } while ($true)
}
catch {
    Write-Host "`n❌ An error occurred: $_" -ForegroundColor Red
    Write-Host "Please try again or contact support.`n" -ForegroundColor Yellow
    pause
}
# Made by Chris or SUxpa2VMaWdodCBvbiBHaXRodWI= <-- Base64 :D