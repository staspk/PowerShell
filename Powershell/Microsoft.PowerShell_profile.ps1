using module .\Kozubenko.Utils.psm1
using module .\Kozubenko.Git.psm1
using module .\Kozubenko.Python.psm1

[String] $global:GLOBALS = "$([System.IO.Path]::GetDirectoryName($PROFILE))\globals"
[Array]  $global:Methods = @("SetStartLocation(`$path = `$PWD.Path)", "NewVar(`$name, `$value = `$PWD.Path)", "SetVar(`$name, `$value)", "DeleteVar(`$varName)")
function AddMethods([Array]$newMethods) {
    $global:Methods = $($global:Methods; $newMethods)
}
AddMethods(
    @(
        "Kozubenko.Python: Activate",
        "Kozubenko.Python: venvInstallRequirements",
        "Kozubenko.Python: venvFreeze",
        "Kozubenko.Python: KillPythonProcesses",
        "Kozubenko.Git: Push",
        "Kozubenko.Git: Github"
    )
)
function List {     # Lists functions in $global:Methods
    foreach ($method in $global:Methods) {  WriteCyan $method  }
}

function Restart {  Invoke-Item $pshome\pwsh.exe; exit  }
function Open($path = $PWD.Path) {
    if (-not(TestPathSilently($path))) { WriteRed "`$path is not a valid path. `$path == $path"; return; }
    if (IsFile($path)) {  explorer.exe "$([System.IO.Path]::GetDirectoryName($path))"  }
    else {  explorer.exe $path  }
}
function VsCode($path = $PWD.Path) {
    if (-not(TestPathSilently($path))) { WriteRed "`$path is not a valid path. `$path == $path"; return; }
    if (IsFile($path)) {  $containingDir = [System.IO.Path]::GetDirectoryName($path); code $containingDir; return; }
    else { code $path }
}

function LoadInGlobals($varToDelete = "") {   # Cleanup while loading-in, e.g. duplicate removal.
    $variables = @{}   # Dict{key==varName, value==varValue}
    $_globals = (Get-Content -Path $GLOBALS)
    
    if(-not($_globals)) {  WriteRed "Globals Empty"; return  }
    Clear-Host

    $lines = [System.Collections.Generic.List[Object]]::new(); $lines.AddRange($_globals)
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $left = $lines[$i].Split("=")[0]
        $right = $lines[$i].Split("=")[1]
        if ($left -eq "" -or $right -eq "" -or $left -eq $varToDelete -or $variables.ContainsKey($left)) {    # is duplicate if $variables.containsKey($left)
            $lines.RemoveAt($i)
            if ($i -ne 0) {
                $i--
            }
        }
        else {
            $variables.Add($left, $right)
            Set-Variable -Name $left -Value $right -Scope Global

            if ($left -ne "startLocation") {    # startLocation visible on most startups anyways, no need to be redundant
                Write-Host "$left" -ForegroundColor White -NoNewline; Write-Host "=$right" -ForegroundColor Gray
            }
        }
    }
    Set-Content -Path $GLOBALS -Value $lines
    Write-Host
}
function SaveToGlobals([string]$varName, $varValue) {
    $lines = (Get-Content -Path $GLOBALS).Split([Environment]::NewLine)
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $left = $lines[$i].Split("=")[0]
        if ($left -eq $varName) {
            $lines[$i] = "$varName=$varValue"
            Set-Content -Path $GLOBALS -Value $lines;   return;
        }
    }
    Add-Content -Path $GLOBALS -Value "$([Environment]::NewLine)$varName=$varValue"; Set-Variable -Name $varName -Value $varValue -Scope Global
}
function NewVar($name, $value = $PWD.Path) {
    if ([string]::IsNullOrEmpty($name)) { return }
    if ($name[0] -eq "$") { $name = $name.Substring(1, $name.Length - 1 ) }
    SaveToGlobals $name $value
    LoadInGlobals
}
function SetVar($name, $value) {
    if ([string]::IsNullOrEmpty($name) -or [string]::IsNullOrEmpty($value)) { return }
    if ($name[0] -eq "$") { $name = $name.Substring(1, $name.Length - 1 ) }
    SaveToGlobals $name $value
    LoadInGlobals
}
function DeleteVar($varName) {  Clear-Host; Write-Host; LoadInGlobals($varName)  }
function SetStartLocation($path = $PWD.Path) {  
    if (-not(TestPathSilently($path))) {
        WriteRed "Given `$path is not a real directory. `$path == $path"; WriteRed "Exiting SetLocation..."; return
	}
	SaveToGlobals "startLocation" $path
	Restart
}

function Display($directory) {
    if(IsDirectory($directory)) {  $directory | Get-ChildItem  }
    else {
        WriteRed "`$directory must be a valid directory. `$directory: $directory"
    }
}

function CheckGlobalsFile() {
    if (-not(TestPathSilently($GLOBALS))) {
        WriteRed "Globals file not found. `$GLOBALS == $GLOBALS"; WriteRed "Disabling Functions: { LoadInGlobals, SaveToGlobals, NewVar, SetVar, DeleteVar } "
        Remove-Item Function:LoadInGlobals; Remove-Item Function:SaveToGlobals; Remove-Item Function:NewVar; Remove-Item Function:SetVar; Remove-Item Function:DeleteVar
        return $false
    }
    return $true
}
function OnOpen() {
    if (CheckGlobalsFile) {
        LoadInGlobals        

        $openedTo = $PWD.Path
        if ($openedTo -ieq "$env:userprofile" -or $openedTo -ieq "C:\WINDOWS\system32") {   # Powershell almost certainly started from taskbar/shortcut, not from right_click->open_in_terminal... No specific directory in mind => checking $GLOBALS:$startLocation
            if ($startLocation -eq $null) {
                # Do Nothing
            }
            elseif(IsDirectory $startLocation) {  Set-Location $startLocation }
            elseif(IsFile $startLocation)      {  Set-Location $([System.IO.Path]::GetDirectoryName($startLocation))  }
            else {
                WriteRed "`$startLocation path does not exist anymore. Defaulting to userdirectory..."
                Start-Sleep -Seconds 3
                Set-Location $Env:USERPROFILE
            }
        }
    }
    Set-PSReadLineKeyHandler -Key Ctrl+z -Function ClearScreen
    Set-PSReadLineKeyHandler -Key Alt+Backspace -Description "Delete Line" -ScriptBlock {
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition(0)
        [Microsoft.PowerShell.PSConsoleReadLine]::KillLine()
    }
    
    SetAliases Restart @("re", "res")
    SetAliases VsCode  @("vs", "vsc")
    SetAliases Clear-Host  @("z")
    SetAliases "C:\Program Files\Notepad++\notepad++.exe" @("note", "npp")
}
OnOpen
