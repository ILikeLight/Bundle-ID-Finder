<# : batch script
@echo off
setlocal
cd %~dp0
powershell -executionpolicy remotesigned -Command "Invoke-Expression $([System.IO.File]::ReadAllText('%~f0'))"
endlocal
goto:eof
#>

# Forceer TLS 1.2 om verbinding met moderne servers te maken
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Vraag de gebruiker om een bron-URL in te voeren
$sourceUrl = Read-Host "Voer de bron-URL in (bijv. https://apps.apple.com/nl/app/safari/id1146562112)"
$lookupUrlBase = "https://itunes.apple.com/lookup?id="

# Extract de laatste 9 of 10 cijfers van de ingevoerde URL
if ($sourceUrl -match "id(\d{9,10})") {
    $appId = $matches[1] # De ID wordt hieruit gehaald
    # Combineer met de lookup-URL
    $lookupUrl = $lookupUrlBase + $appId
    Write-Output "Generated Lookup URL: $lookupUrl"
    
    # Download het bestand
    $outputPath = Join-Path $env:USERPROFILE "Downloads\lookup_result.txt"  # Kies een geschikte bestandsnaam
    Invoke-WebRequest -Uri $lookupUrl -OutFile $outputPath
    Write-Output "Bestand gedownload naar: $outputPath"

    # Lees de inhoud van het bestand
    $fileContent = Get-Content $outputPath -Raw

    # Zoek de waarde van "bundleId"
    if ($fileContent -match '"bundleId":"([^"]+)"') {
        $bundleId = $matches[1]
        Write-Output "Gevonden bundleId: $bundleId"
    } else {
        Write-Output "Kon geen bundleId vinden in het bestand."
		# Pauzeer om het venster open te houden
        Read-Host "Druk op Enter om af te sluiten"
    }
    
} else {
    Write-Output "Kon geen geldige ID vinden in de ingevoerde URL."
	# Pauzeer om het venster open te houden
    Read-Host "Druk op Enter om af te sluiten"
}

# Pauzeer om het venster open te houden
Read-Host "Druk op Enter om af te sluiten"
# Made by Chris or SUxpa2VMaWdodCBvbiBHaXRodWI= <-- Base64 :D
