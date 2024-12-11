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
    Apple App Store Bundle ID Retriever with History and Version Check
.DESCRIPTION
    This script extracts bundle IDs from Apple App Store links, maintains a history of lookups,
    and automatically copies Bundle ID to clipboard.
.AUTHOR
    ILikeLight
.VERSION
    1.3.3
#>

# GitHub repository information
$GITHUB_REPO = "ILikeLight/Bundle-ID-Finder"
$CURRENT_VERSION = "1.3.3"

# Add necessary .NET type for clipboard access
Add-Type -AssemblyName System.Windows.Forms

# Global settings variable
$global:AppSettings = @{
    AutoCopyToClipboard = $true
    MaxHistoryEntries = 1000
    DefaultExportFormat = "CSV"
    ColoredOutput = $true
    CheckReleaseNotes = $true
}

# Function to create default settings file
function Create-DefaultSettingsFile {
    $settingsPath = Join-Path $env:USERPROFILE "AppStoreBundleIDSettings.json"
    
    try {
        $defaultSettings = @{
            AutoCopyToClipboard = $true
            MaxHistoryEntries = 1000
            DefaultExportFormat = "CSV"
            ColoredOutput = $true
            CheckReleaseNotes = $true
        }
        
        $defaultSettings | ConvertTo-Json | Set-Content $settingsPath
        Write-Host "✨ Default settings file created at: $settingsPath" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Error creating default settings file: $_" -ForegroundColor Red
    }
}

# Function to load settings from file
function Load-Settings {
    $settingsPath = Join-Path $env:USERPROFILE "AppStoreBundleIDSettings.json"
    
    if (Test-Path $settingsPath) {
        try {
            $savedSettings = Get-Content $settingsPath | ConvertFrom-Json
            
            # Update global settings with saved settings
            foreach ($key in $savedSettings.PSObject.Properties.Name) {
                $global:AppSettings[$key] = $savedSettings.$key
            }
            Write-Host "✅ Settings loaded successfully!" -ForegroundColor Green
        }
        catch {
            Write-Host "❌ Error loading settings: $_" -ForegroundColor Red
            # Create default settings file if loading fails
            Create-DefaultSettingsFile
        }
    }
    else {
        # Create default settings file if it doesn't exist
        Create-DefaultSettingsFile
    }
}

# Function to save settings to file
function Save-Settings {
    $settingsPath = Join-Path $env:USERPROFILE "AppStoreBundleIDSettings.json"
    
    try {
        $global:AppSettings | ConvertTo-Json | Set-Content $settingsPath
        Write-Host "✅ Settings saved successfully!" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Error saving settings: $_" -ForegroundColor Red
    }
}

# Function to display and edit settings
function Edit-Settings {
    do {
        Clear-Host
        Write-Host "⚙️ Application Settings" -ForegroundColor Cyan
        Write-Host "======================" -ForegroundColor Cyan
        Write-Host "1. Auto Copy to Clipboard: " -NoNewline -ForegroundColor Yellow
        Write-Host $(if ($global:AppSettings.AutoCopyToClipboard) { "Enabled" } else { "Disabled" }) -ForegroundColor Green
        Write-Host "2. Max History Entries: " -NoNewline -ForegroundColor Yellow
        Write-Host $global:AppSettings.MaxHistoryEntries -ForegroundColor Green
        Write-Host "3. Default Export Format: " -NoNewline -ForegroundColor Yellow
        Write-Host $global:AppSettings.DefaultExportFormat -ForegroundColor Green
        Write-Host "4. Colored Output: " -NoNewline -ForegroundColor Yellow
        Write-Host $(if ($global:AppSettings.ColoredOutput) { "Enabled" } else { "Disabled" }) -ForegroundColor Green
        Write-Host "5. Check for updates: " -NoNewline -ForegroundColor Yellow
        Write-Host $(if ($global:AppSettings.CheckReleaseNotes) { "Enabled" } else { "Disabled" }) -ForegroundColor Green
        Write-Host "6. Return to Main Menu" -ForegroundColor Cyan
        
        Write-Host "`nEnter the number of the setting you want to modify: " -NoNewline -ForegroundColor Yellow
        $choice = Read-Host
        
        switch ($choice) {
            "1" {
                $global:AppSettings.AutoCopyToClipboard = -not $global:AppSettings.AutoCopyToClipboard
            }
            "2" {
                Write-Host "Enter the maximum number of history entries (current: $($global:AppSettings.MaxHistoryEntries)): " -NoNewline -ForegroundColor Yellow
                $maxEntries = Read-Host
                if ($maxEntries -match '^\d+$') {
                    $global:AppSettings.MaxHistoryEntries = [int]$maxEntries
                }
                else {
                    Write-Host "❌ Invalid input. Please enter a number." -ForegroundColor Red
                    Start-Sleep -Seconds 2
                }
            }
            "3" {
                $formats = @("CSV", "JSON")
                Write-Host "Select export format:" -ForegroundColor Yellow
                for ($i = 0; $i -lt $formats.Length; $i++) {
                    Write-Host "$($i+1). $($formats[$i])" -ForegroundColor Cyan
                }
                $formatChoice = Read-Host
                if ($formatChoice -match '^[12]$') {
                    $global:AppSettings.DefaultExportFormat = $formats[$formatChoice - 1]
                }
            }
            "4" {
                $global:AppSettings.ColoredOutput = -not $global:AppSettings.ColoredOutput
            }
            "5" {
                $global:AppSettings.CheckReleaseNotes = -not $global:AppSettings.CheckReleaseNotes
            }
            "6" {
                Save-Settings
				Start-Sleep -Seconds 2
				break
            }
            default {
                Write-Host "❌ Invalid choice!" -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    } while ($choice -ne "6")
}

function Show-ReleaseNotes {
    try {
        # Fetch the latest release information from GitHub
        $releaseUrl = "https://api.github.com/repos/$GITHUB_REPO/releases/latest"
        $response = Invoke-RestMethod -Uri $releaseUrl -Method Get

        Write-Host "`n📝 Detailed Release Notes" -ForegroundColor Yellow
        Write-Host "========================" -ForegroundColor Yellow
        Write-Host "Version: " -NoNewline -ForegroundColor Cyan
        Write-Host $response.tag_name -ForegroundColor Green
        Write-Host "Published: " -NoNewline -ForegroundColor Cyan
        Write-Host $response.published_at -ForegroundColor Gray
        Write-Host "`nChanges:" -ForegroundColor Yellow
        Write-Host $response.body -ForegroundColor White
        
        Write-Host "`nDownload Link: " -NoNewline -ForegroundColor Cyan
        Write-Host $response.html_url -ForegroundColor Magenta
    }
    catch {
        Write-Host "`n❌ Could not retrieve release notes. " -ForegroundColor Yellow -NoNewline
        Write-Host "($($_.Exception.Message))" -ForegroundColor Gray
    }
}

# this function checks for updates
function Check-ScriptUpdate {
    # Only check for updates if the setting is enabled
    if (-not $global:AppSettings.CheckReleaseNotes) {
        return
    }

    try {
        # Fetch the latest release information from GitHub
        $releaseUrl = "https://api.github.com/repos/$GITHUB_REPO/releases/latest"
        $response = Invoke-RestMethod -Uri $releaseUrl -Method Get

        # Extract the latest version (removing 'v' prefix if present)
        $latestVersion = $response.tag_name -replace '^v', ''

        # Compare versions
        $currentParts = $CURRENT_VERSION.Split('.')
        $latestParts = $latestVersion.Split('.')

        $needsUpdate = $false
        $isUnreleasedVersion = $false

        for ($i = 0; $i -lt [Math]::Min($currentParts.Length, $latestParts.Length); $i++) {
            if ([int]$latestParts[$i] -gt [int]$currentParts[$i]) {
                $needsUpdate = $true
                break
            }
            elseif ([int]$latestParts[$i] -lt [int]$currentParts[$i]) {
                $isUnreleasedVersion = $true
                break
            }
        }

        if ($isUnreleasedVersion -or $currentParts.Length -gt $latestParts.Length) {
            Write-Host "🚀 Unreleased Version Detected! 🌟" -ForegroundColor Magenta
            Write-Host "Current Version: " -NoNewline
            Write-Host $CURRENT_VERSION -ForegroundColor Cyan
            Write-Host "Latest Public Version: " -NoNewline
            Write-Host $latestVersion -ForegroundColor Green
            Write-Host "You are running a development or pre-release version." -ForegroundColor Cyan
            return
        }

        if ($needsUpdate -or $latestParts.Length -gt $currentParts.Length) {
            Write-Host "🚨 Update Available!" -ForegroundColor Yellow
            Write-Host "Current Version: " -NoNewline
            Write-Host $CURRENT_VERSION -ForegroundColor Cyan
            Write-Host "Latest Version:  " -NoNewline
            Write-Host $latestVersion -ForegroundColor Green
            
            # Automatically show release notes when an update is available
            Show-ReleaseNotes
        }
    }
    catch {
        Write-Host "`n❌ Could not check for updates. " -ForegroundColor Yellow -NoNewline
        Write-Host "($($_.Exception.Message))" -ForegroundColor Gray
        return
    }
}

# Function to display fancy banner (updated to include version)
function Show-Banner {
    Clear-Host
    Write-Host "===============================================" -ForegroundColor Cyan
    Write-Host "     🍎 Apple Store Bundle ID Retriever 🔍" -ForegroundColor Yellow
    Write-Host "               Version $CURRENT_VERSION" -ForegroundColor Gray
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
    
    # Limit history entries based on settings
    if ($history.Lookups.Count -ge $global:AppSettings.MaxHistoryEntries) {
        $history.Lookups = $history.Lookups | 
            Sort-Object Timestamp -Descending | 
            Select-Object -First $global:AppSettings.MaxHistoryEntries
    }
    
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

# New function to export history
function Export-History {
    param (
        [string]$Format = "CSV",
        [string]$OutputPath = ""
    )

    $history = Get-Content $historyPath | ConvertFrom-Json

    if ($history.Lookups.Count -eq 0) {
        Write-Host "❌ No history to export!" -ForegroundColor Red
        return
    }

    # If no output path specified, prompt user
    if ([string]::IsNullOrWhiteSpace($OutputPath)) {
        $defaultFileName = "AppStoreBundleIDHistory_" + (Get-Date -Format "yyyyMMdd_HHmmss")
        
        if ($Format -eq "CSV") {
            $defaultFileName += ".csv"
            $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
            $saveDialog.Filter = "CSV Files (*.csv)|*.csv"
            $saveDialog.FileName = $defaultFileName
            $saveDialog.Title = "Export History to CSV"
            
            if ($saveDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $OutputPath = $saveDialog.FileName
            }
            else {
                Write-Host "❌ Export cancelled." -ForegroundColor Red
                return
            }
        }
        else {
            $defaultFileName += ".json"
            $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
            $saveDialog.Filter = "JSON Files (*.json)|*.json"
            $saveDialog.FileName = $defaultFileName
            $saveDialog.Title = "Export History to JSON"
            
            if ($saveDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $OutputPath = $saveDialog.FileName
            }
            else {
                Write-Host "❌ Export cancelled." -ForegroundColor Red
                return
            }
        }
    }

    try {
        if ($Format -eq "CSV") {
            $history.Lookups | 
                Select-Object Timestamp, AppStoreUrl, BundleId, AppName | 
                Export-Csv -Path $OutputPath -NoTypeInformation
        }
        else {
            $history | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath
        }

        Write-Host "✅ History exported successfully to:" -ForegroundColor Green
        Write-Host $OutputPath -ForegroundColor Cyan
    }
    catch {
        Write-Host "❌ Export failed: $_" -ForegroundColor Red
    }
}
# Function to copy to clipboard
function Copy-BundleId {
    param (
        [string]$BundleId
    )

    if (-not $global:AppSettings.AutoCopyToClipboard) {
        return
    }

    if (-not [string]::IsNullOrWhiteSpace($BundleId)) {
        [System.Windows.Forms.Clipboard]::SetText($BundleId)
        if ($global:AppSettings.ColoredOutput) {
            Write-Host "📋 Bundle ID copied to clipboard: " -NoNewline -ForegroundColor Green
            Write-Host $BundleId -ForegroundColor Cyan
        }
        else {
            Write-Host "Bundle ID copied to clipboard: $BundleId"
        }
    }
    else {
        if ($global:AppSettings.ColoredOutput) {
            Write-Host "❌ No Bundle ID to copy!" -ForegroundColor Red
        }
        else {
            Write-Host "No Bundle ID to copy!"
        }
    }
}

# New function to process batch URLs from a file
function Process-BatchUrls {
    param ([string]$FilePath)

    if (-not (Test-Path $FilePath)) {
        Write-Host "❌ File not found: $FilePath" -ForegroundColor Red
        return
    }

    $urls = Get-Content $FilePath | Where-Object { 
        -not [string]::IsNullOrWhiteSpace($_) -and (Test-AppStoreUrl $_) 
    }

    if ($urls.Count -eq 0) {
        Write-Host "❌ No valid URLs found in the file!" -ForegroundColor Red
        return
    }

    Write-Host "`n🔍 Processing Batch URLs..." -ForegroundColor Cyan
    $results = @()

    foreach ($url in $urls) {
        $appId = Get-AppId $url
        if ($null -ne $appId) {
            $result = Get-BundleId $appId
            if ($null -ne $result) {
                $results += [PSCustomObject]@{
                    Url = $url
                    AppName = $result.AppName
                    BundleId = $result.BundleId
                }
                Add-ToHistory -AppStoreUrl $url -BundleId $result.BundleId -AppName $result.AppName
            }
        }
    }

    if ($results.Count -gt 0) {
        Write-Host "`n✅ Batch Processing Results:" -ForegroundColor Green
        $results | Format-Table -AutoSize
        
        # Option to export results
        $exportChoice = Read-Host "`nDo you want to export these results? (Y/N)"
        if ($exportChoice -eq 'Y') {
            $defaultFileName = "BatchBundleIDResults_" + (Get-Date -Format "yyyyMMdd_HHmmss")
            $results | Export-Csv -Path "$defaultFileName.csv" -NoTypeInformation
            Write-Host "📄 Results exported to $defaultFileName.csv" -ForegroundColor Green
        }
    }
    else {
        Write-Host "❌ No valid results found!" -ForegroundColor Red
    }
}

# Updated Show-Menu function
function Show-Menu {
    Clear-Host
    Show-Banner
    Check-ScriptUpdate
    Write-Host "Please choose an option:" -ForegroundColor Yellow
    Write-Host "1. " -NoNewline -ForegroundColor Cyan
    Write-Host "Look up Bundle ID by URL"
    Write-Host "2. " -NoNewline -ForegroundColor Cyan
    Write-Host "Search Bundle ID by App Name"
    Write-Host "3. " -NoNewline -ForegroundColor Cyan
    Write-Host "History Management"
    Write-Host "4. " -NoNewline -ForegroundColor Cyan
    Write-Host "Process Batch URLs"
    Write-Host "5. " -NoNewline -ForegroundColor Cyan
    Write-Host "Settings"
    Write-Host "6. " -NoNewline -ForegroundColor Cyan
    Write-Host "Exit"
    Write-Host ""
    Write-Host "Tip: You can directly paste a URL to look it up!" -ForegroundColor DarkGray
    Write-Host "Enter your choice or URL: " -NoNewline -ForegroundColor Yellow
}

function Show-HistoryMenu {
    do {
        Clear-Host
		Show-Banner
        Write-Host "📜 History Management" -ForegroundColor Yellow
        Write-Host "====================`n" -ForegroundColor Yellow
        Write-Host "1. View History" -ForegroundColor Cyan
        Write-Host "2. Clear History" -ForegroundColor Cyan
        Write-Host "3. Export History" -ForegroundColor Cyan
        Write-Host "4. Return to Main Menu" -ForegroundColor Cyan
        Write-Host "`nEnter your choice: " -NoNewline -ForegroundColor Yellow
        
        $historyChoice = Read-Host
        
        switch ($historyChoice) {
            "1" {
                Show-History
                pause
            }
            "2" {
                @{
                    "LastUpdated" = (Get-Date).ToString()
                    "Lookups" = @()
                } | ConvertTo-Json | Set-Content $historyPath
                Write-Host "`n✨ History cleared successfully!`n" -ForegroundColor Green
                pause
            }
            "3" {
                # Export history submenu
                while ($true) {
                    Write-Host "`nExport History:" -ForegroundColor Yellow
                    Write-Host "1. Export as CSV" -ForegroundColor Cyan
                    Write-Host "2. Export as JSON" -ForegroundColor Cyan
                    Write-Host "3. Return to History Menu" -ForegroundColor Cyan
                    
                    $exportChoice = Read-Host "Choose an export format"
                    
                    switch ($exportChoice) {
                        "1" { Export-History -Format "CSV"; break }
                        "2" { Export-History -Format "JSON"; break }
                        "3" { break }
                        default { 
                            Write-Host "`n❌ Invalid choice!" -ForegroundColor Red
                        }
                    }
                    
                    if ($exportChoice -eq "3") { break }
                    
                    pause
                }
            }
            "4" {
                return
            }
            default {
                Write-Host "`n❌ Invalid choice!" -ForegroundColor Red
                pause
            }
        }
    } while ($true)
}

# Process-UrlLookup function to automatically copy to clipboard
function Process-UrlLookup {
    param ([string]$url)
    
    if (-not (Test-AppStoreUrl $url)) {
        Write-Host "`n❌ Invalid Apple Store URL format!`n" -ForegroundColor Red
        return $null
    }
    
    Write-Host "`n🔍 Processing..." -ForegroundColor Cyan
    
    $appId = Get-AppId $url
    if ($null -eq $appId) {
        Write-Host "❌ Could not extract App ID from URL!`n" -ForegroundColor Red
        return $null
    }
    
    $result = Get-BundleId $appId
    if ($null -ne $result) {
        Write-Host "`n✅ Results:" -ForegroundColor Green
        Write-Host "App Name: " -NoNewline -ForegroundColor Yellow
        Write-Host $result.AppName
        Write-Host "Bundle ID: " -NoNewline -ForegroundColor Yellow
        Write-Host $result.BundleId
        
        Add-ToHistory -AppStoreUrl $url -BundleId $result.BundleId -AppName $result.AppName
        
        # Automatically copy Bundle ID to clipboard
        Copy-BundleId -BundleId $result.BundleId
        
        
    }
    return $null
}

# Main script execution
try {
	# load settings before initializing
	Load-Settings
    
	Initialize-HistoryFile
	
    # Check for updates before showing the menu
    Check-ScriptUpdate

    do {
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
                    Write-Host "Enter Apple Store URL (or press Enter to return to menu): " -NoNewline -ForegroundColor Yellow
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
                    Write-Host "`nThis feature searches your local history for ID's" -ForegroundColor DarkGray
                    Write-Host "Enter App Name to search (or press Enter to return to menu): " -NoNewline -ForegroundColor Yellow
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
                Show-HistoryMenu
            }
            "4" {
                # Batch URL processing
                Write-Host "`nEnter the path to a text file with App Store URLs (one per line): " -NoNewline -ForegroundColor Yellow
                $filePath = Read-Host
                
                if (-not [string]::IsNullOrWhiteSpace($filePath)) {
                    Process-BatchUrls $filePath
                    pause
                }
            }
            "5" {
                Edit-Settings
            }
            "6" {
                Write-Host "`n👋 Goodbye!" -ForegroundColor Cyan
                exit
            }
            default {
                Write-Host "`n❌ Invalid choice! Please select 1-6 or paste a valid Apple Store URL.`n" -ForegroundColor Red
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
finally {
	Start-Sleep -Seconds 1
}
# Made by Chris or SUxpa2VMaWdodCBvbiBHaXRodWI= <-- Base64 :D