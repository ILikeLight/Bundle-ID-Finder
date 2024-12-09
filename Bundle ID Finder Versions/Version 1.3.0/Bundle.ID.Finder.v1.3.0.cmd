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
    ILikeLight
.VERSION
    1.3.0
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

    # Group lookups by BundleId and sort by timestamp
    $groupedLookups = $history.Lookups | 
        Group-Object BundleId | 
        ForEach-Object {
            $group = $_.Group | Sort-Object Timestamp -Descending
            [PSCustomObject]@{
                BundleId = $_.Name
                Count = $_.Count
                Entries = $group
            }
        } | 
        Sort-Object { $_.Entries[0].Timestamp } -Descending

    Write-Host "`n📜 Lookup History (last 2 per Bundle ID):" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    
    foreach ($bundleGroup in $groupedLookups) {
        $firstEntry = $bundleGroup.Entries[0]
        
        Write-Host "`nApp Name: " -NoNewline -ForegroundColor Yellow
        Write-Host $firstEntry.AppName
        Write-Host "Bundle ID: " -NoNewline -ForegroundColor Yellow
        Write-Host $bundleGroup.BundleId -ForegroundColor Green
        
        # Show count if more than one lookup
        if ($bundleGroup.Count -gt 1) {
            Write-Host "Total Lookups: " -NoNewline -ForegroundColor Yellow
            Write-Host $bundleGroup.Count -ForegroundColor Magenta
        }
        
        # Display the last two timestamps and URLs
        $recentEntries = $bundleGroup.Entries | Select-Object -First 2
        Write-Host "Last Lookups:" -ForegroundColor Yellow
        foreach ($entry in $recentEntries) {
            Write-Host "  - Timestamp: " -NoNewline -ForegroundColor Cyan
            Write-Host $entry.Timestamp -ForegroundColor Gray
            Write-Host "    URL: " -NoNewline -ForegroundColor Cyan
            Write-Host $entry.AppStoreUrl -ForegroundColor Gray
        }
        
        Write-Host "-------------------" -ForegroundColor DarkGray
    }
}

# Function to search for app by name in history
function Search-AppByName {
    param ([string]$AppName)
    
    $history = Get-Content $historyPath | ConvertFrom-Json
    
    # Case-insensitive partial name match
    $matchedApps = $history.Lookups | 
        Where-Object { $_.AppName -like "*$AppName*" } | 
        Group-Object BundleId | 
        ForEach-Object {
            $group = $_.Group | Sort-Object Timestamp -Descending
            [PSCustomObject]@{
                BundleId = $_.Name
                AppName = $group[0].AppName
                LatestTimestamp = $group[0].Timestamp
                Url = $group[0].AppStoreUrl
                Count = $_.Count
            }
        } | 
        Sort-Object LatestTimestamp -Descending

    if ($matchedApps.Count -eq 0) {
        Write-Host "`n❌ No apps found matching '$AppName'`n" -ForegroundColor Red
        return
    }

    Write-Host "`n🔍 Search Results for '$AppName':" -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan

    foreach ($app in $matchedApps) {
        Write-Host "`nApp Name: " -NoNewline -ForegroundColor Yellow
        Write-Host $app.AppName
        Write-Host "Bundle ID: " -NoNewline -ForegroundColor Yellow
        Write-Host $app.BundleId -ForegroundColor Green
        Write-Host "Latest Lookup: " -NoNewline -ForegroundColor Yellow
        Write-Host $app.LatestTimestamp -ForegroundColor Gray
        Write-Host "Last Known URL: " -NoNewline -ForegroundColor Yellow
        Write-Host $app.Url -ForegroundColor Gray
        
        if ($app.Count -gt 1) {
            Write-Host "Total Lookups: " -NoNewline -ForegroundColor Yellow
            Write-Host $app.Count -ForegroundColor Magenta
        }
        
        Write-Host "-------------------" -ForegroundColor DarkGray
    }

    # Remove or comment out the return line to prevent automatic display
    # return $matchedApps
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
    Write-Host "Please choose an option:" -ForegroundColor Yellow
    Write-Host "1. " -NoNewline -ForegroundColor Cyan
    Write-Host "Look up Bundle ID by URL"
    Write-Host "2. " -NoNewline -ForegroundColor Cyan
    Write-Host "Search Bundle ID by App Name"
    Write-Host "3. " -NoNewline -ForegroundColor Cyan
    Write-Host "View History"
    Write-Host "4. " -NoNewline -ForegroundColor Cyan
    Write-Host "Clear History"
    Write-Host "5. " -NoNewline -ForegroundColor Cyan
    Write-Host "Exit"
	Write-Host ""
    Write-Host "Tip: You can directly paste a URL to look it up!" -ForegroundColor DarkGray
    Write-Host "Enter your choice or URL: " -NoNewline -ForegroundColor Yellow
}

# Function to process URL lookup
function Process-UrlLookup {
    param ([string]$url)
    
    if (-not (Test-AppStoreUrl $url)) {
        Write-Host "`n❌ Invalid Apple Store URL format!`n" -ForegroundColor Red
        return $false
    }
    
    Write-Host "`n🔍 Processing..." -ForegroundColor Cyan
    
    $appId = Get-AppId $url
    if ($null -eq $appId) {
        Write-Host "❌ Could not extract App ID from URL!`n" -ForegroundColor Red
        return $false
    }
    
    $result = Get-BundleId $appId
    if ($null -ne $result) {
        Write-Host "`n✅ Results:" -ForegroundColor Green
        Write-Host "App Name: " -NoNewline -ForegroundColor Yellow
        Write-Host $result.AppName
        Write-Host "Bundle ID: " -NoNewline -ForegroundColor Yellow
        Write-Host $result.BundleId
        
        Add-ToHistory -AppStoreUrl $url -BundleId $result.BundleId -AppName $result.AppName
        return $true
    }
    return $false
}

# Main script execution
try {
    Initialize-HistoryFile
    
    do {
        Show-Banner
        Show-Menu
        $input = Read-Host
        
        # Check if input is a URL
        if (Test-AppStoreUrl $input) {
            # Continuous URL processing loop from main menu
            while ($true) {
                Process-UrlLookup $input
                Write-Host "`nEnter another Apple Store URL (or press Enter to return to menu): " -NoNewline -ForegroundColor Yellow
                $input = Read-Host
                
                # Break the loop and return to main menu if no URL is entered
                if ([string]::IsNullOrWhiteSpace($input)) {
                    break
                }
                
                # Check if the new input is a valid URL, otherwise break
                if (-not (Test-AppStoreUrl $input)) {
                    Write-Host "`n❌ Invalid Apple Store URL format!`n" -ForegroundColor Red
                    break
                }
            }
            continue
        }
        
        switch ($input) {
            "1" {
                # Continuous URL entry loop
                while ($true) {
                    Write-Host "`nEnter Apple Store URL (or press Enter to return to menu): " -NoNewline -ForegroundColor Yellow
                    $url = Read-Host
                    
                    # Break the inner loop and return to main menu if no URL is entered
                    if ([string]::IsNullOrWhiteSpace($url)) {
                        break
                    }
                    
                    Process-UrlLookup $url
                    Write-Host "`n"
                }
            }
            "2" {
                # Search by app name loop
                while ($true) {
                    Write-Host "`nEnter App Name to search (or press Enter to return to menu): " -NoNewline -ForegroundColor Yellow
                    $appName = Read-Host
                    
                    # Break the inner loop and return to main menu if no name is entered
                    if ([string]::IsNullOrWhiteSpace($appName)) {
                        break
                    }
                    
                    Search-AppByName $appName
                    Write-Host "`n"
                }
            }
            "3" {
                Show-History
                Write-Host "`n"
                pause
            }
            "4" {
                @{
                    "LastUpdated" = (Get-Date).ToString()
                    "Lookups" = @()
                } | ConvertTo-Json | Set-Content $historyPath
                Write-Host "`n✨ History cleared successfully!`n" -ForegroundColor Green
                pause
            }
            "5" {
                Write-Host "`n👋 Goodbye!" -ForegroundColor Cyan
                exit
            }
            default {
                Write-Host "`n❌ Invalid choice! Please select 1-5 or paste a valid Apple Store URL.`n" -ForegroundColor Red
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
