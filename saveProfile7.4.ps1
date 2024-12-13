# Deletes the contents of: .\Powershell, and copy pastes everything under the Powershell $profile to ScriptPackage

$profileDir = "$env:USERPROFILE\Documents\Powershell"
$scriptDir = ".\Powershell"

Get-ChildItem -Path $scriptDir -Recurse | ForEach-Object {
    $_.Delete()
    Write-Host "Deleted File: $_" -ForegroundColor Red
}

Copy-Item -Path "$profileDir\*" -Destination $scriptDir -Recurse