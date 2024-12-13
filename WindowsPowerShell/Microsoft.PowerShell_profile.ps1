using module .\Kozubenko.Utils.psm1
using module .\Kozubenko.Git.psm1

$GLOBALS = "$([System.IO.Path]::GetDirectoryName($PROFILE))\globals"

function Restart { wt.exe; exit }
function Open($path) {
    if ($path -eq $null) {  Invoke-Item .; return; }
    if (-not(TestPathSilently($path))) { WriteRed "`$path is not a valid path. `$path == $path"; return; }
    if (IsFile($path)) {  Invoke-Item  $([System.IO.Path]::GetDirectoryName($path))  }
    else {  Invoke-Item $path  }
}
function VsCode ($path) {
    if ($path -eq $null) {  code .; return; }
    if (-not(TestPathSilently($path))) { WriteRed "`$path is not a valid path. `$path == $path"; return; }
    if (IsFile($path)) {  $containingDir = [System.IO.Path]::GetDirectoryName($path); code $containingDir; return; }
    else { code $path }
}
function LoadInGlobals() {
    $variables = @{}   # Dict{key==varName, value==varValue}
    $lines = (Get-Content -Path $GLOBALS).Split([Environment]::NewLine)
    $lines2 = New-Object System.Collections.Generic.List[System.String]
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $left = $lines[$i].Split("=")[0]; $right = $lines[$i].Split("=")[1]
        if (-not([string]::IsNullOrEmpty($left)) -AND -not([string]::IsNullOrEmpty($right))) {
            if (-not($variables.ContainsKey($left))) {
                $variables.Add($left, $right)
                $lines2.Add($lines[$i])
                if (-not(Get-Variable -Name $left -Scope Global -ErrorAction SilentlyContinue)) {
                    New-Variable -Name $left -Value $right -Scope Global  }
                else {
                    Set-Variable -Name $left -Value $right -Scope Global
                }
                if ($left -ne "startLocation") {    # startLocation visible on most startups anyways, no need to be redundant
                    Write-Host "$left" -ForegroundColor White -NoNewline; Write-Host "=$right" -ForegroundColor Gray
                }
            }
        }
    }
    Set-Content -Path $GLOBALS -Value $lines2
}
function SaveToGlobals([string]$varName, $varValue) {
    $lines = (Get-Content -Path $GLOBALS).Split([Environment]::NewLine)
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        $left = $line.Split("=")[0]
        if ($left -eq $varName) {
            $lines[$i] = "$varName=$varValue"
            Set-Content -Path $GLOBALS -Value $lines;  return;
        }
    }
    Add-Content -Path $GLOBALS -Value "$varName=$varValue"; New-Variable -Name $varName -Value $varValue -Scope Global
}
function NewVar($name, $value) {
    if ($value -eq $null) { $value = $PWD.Path }
    SaveToGlobals $name $value
    Clear-Host; LoadInGlobals; Write-Host
}
function CheckGlobalsFile() {
    if (-not(TestPathSilently($GLOBALS))) {
        WriteRed "Globals file not found. Set path to globals at top of `$Profile `$GLOBALS == $GLOBALS"; WriteRed "Disabling Functions: LoadInGlobals, SaveToGlobals, NewVar"
        Remove-Item Function:LoadInGlobals; Remove-Item Function:SaveToGlobals; Remove-Item Function:NewVar; 
        return $false
    }
    return $true
}

function SetLocation($path = $PWD.Path) {
    if (-not(TestPathSilently($path))) {
        WriteRed "Given `$path is not a real directory. `$path == $path"; WriteRed "Exiting SetLocation..."; return
	}
	SaveToGlobals "startLocation" $path
	Restart
}

function OnOpen() {
    if (CheckGlobalsFile) {
        LoadInGlobals

        $openedTo = $PWD.Path
        Write-Host
        if ($openedTo -ieq "$env:userprofile" -or $openedTo -ieq "C:\WINDOWS\system32") {  # Did Not start Powershell from a specific directory in mind; Set-Location to $startLocation.
            if ($startLocation -eq $null) {
                # Do Nothing
            }
            elseif (TestPathSilently $startLocation) {
                Set-Location $startLocation  }
            else {
                WriteRed "`$startLocation path does not exist anymore. Defaulting to userdirectory..."
                Start-Sleep -Seconds 3
                SetLocation $Env:USERPROFILE
            }
        }
    }
}
Clear-Host
OnOpen