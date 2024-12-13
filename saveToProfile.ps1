# .\WindowsPowerShell == 5.1, .\Powershell == 7.4+. Careful: deletes everything under profile directory before copy-pasting files into.

$profile5Dir = "$env:USERPROFILE\Documents\WindowsPowerShell\"
$profile7Dir = "$env:USERPROFILE\Documents\Powershell\"
$scriptDir = ".\WindowsPowerShell"

Get-ChildItem -Path $scriptDir -Recurse | ForEach-Object {
    $_.Delete()
    Write-Host "Deleted File: $_"
}

Copy-Item -Path "$profileDir\*" -Destination $scriptDir -Recurse