# Deletes the contents of: .\WindowsPowerShell, and copy pastes everything under the WindowsPowerShell $profile to ScriptPackage

$profileDir = "$env:USERPROFILE\Documents\WindowsPowerShell"
$scriptDir = ".\WindowsPowerShell"

Get-ChildItem -Path $scriptDir -Recurse | ForEach-Object {
    $_.Delete()
    Write-Host "Deleted File: $_"
}

Copy-Item -Path "$profileDir\*" -Destination $scriptDir -Recurse