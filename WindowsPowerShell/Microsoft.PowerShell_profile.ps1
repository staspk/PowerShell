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
        if (-not([string]::IsNullOrEmpty($array[0])) -AND -not([string]::IsNullOrEmpty($array[1]))) {
            New-Variable -Name $array[0] -Value $array[1] -Scope Global
            Write-Host "$($array[0])" -ForegroundColor White -NoNewline; Write-Host "=$($array[1])" -ForegroundColor Gray
        }
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
    if($path -eq $null) {  SaveToGlobals "startLocation" $PWD.Path; Restart; }
    elseif (-not(TestPathSilently($path))) {
		return;
	}
	SaveToGlobals "startLocation" $path
	Restart
}

function OnOpen() {
	$openedTo = $PWD.Path
    Clear-Host
	LoadInGlobals
    Write-Host
	if ($openedTo -eq "$env:userprofile" -or $openedTo -eq "C:\WINDOWS\system32") {  # Did Not start Powershell from a specific directory in mind; Set-Location to default.
        if ($startLocation -eq $null) {
            break
        }
        if (TestPathSilently $startLocation) {
            Set-Location $startLocation  }
        else {
            Write-Host "`$startLocation path does not exist anymore. Defaulting to userdirectory..."  -ForegroundColor Red
            Start-Sleep -Seconds 3
            SetLocation $Env:USERPROFILE
        }
    }
}
OnOpen