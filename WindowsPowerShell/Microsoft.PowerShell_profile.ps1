# Import-Module "$PsScriptRoot\Kozubenko.Git.psm1" -Force
# Import-Module "$PsScriptRoot\Kozubenko.Utils.psm1" -Force
using module .\Kozubenko.Utils.psm1
using module .\Kozubenko.Git.psm1
function Restart { wt.exe; exit }
function Open($path) {
    if($path) {  ii  $([System.IO.Path]::GetDirectoryName($path))  }
    else {  ii .  } 
}
function LoadInGlobals() {
    $GLOBALS = "$([System.IO.Path]::GetDirectoryName($PROFILE))\globals"
    foreach($line in [System.IO.File]::ReadLines($GLOBALS)) {
        $array = $line.Split("=")
        New-Variable -Name $array[0] -Value $array[1] -Scope Global
        Write-Host "$($array[0])" -ForegroundColor White -NoNewline; Write-Host "=$($array[1])" -ForegroundColor Gray
    }
}
function SaveToGlobals([string]$varName, $varValue) {
    $GLOBALS = "$([System.IO.Path]::GetDirectoryName($PROFILE))\globals"
    $lines = Get-Content -Path $GLOBALS
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $left = $($lines[$i].Split("="))[0]
        if ($left -eq $varName) {
            $lines[$i] = "$($varName)=$($varValue)"
            $lines | Set-Content -Path $GLOBALS;  return;
        }
    }
    Add-Content -Path $GLOBALS -Value "$varName=$varValue"; New-Variable -Name $varName -Value $varValue -Scope Global
}
function SetLocation($path) {
    if($path -eq $null) {  SaveToGlobals "startLocation" $PWD.Path  }
    elseif (Test-Path($path)) {
        SaveToGlobals "startLocation" $path
    } 
    Set-Location $startLocation
}

function OnOpen() {
	$openedTo = $PWD.Path
    Clear-Host
	LoadInGlobals
    Write-Host
	if ($openedTo -eq "$env:userprofile" -or $openedTo -eq "C:\WINDOWS\system32") { Set-Location $startLocation }   # Did Not start Powershell, with specific directory in mind.
    
}
OnOpen