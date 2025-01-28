function WriteRed($msg, $noNewLine = $false)      {  if($noNewLine) { Write-Host $msg -ForegroundColor Red -NoNewline } else { Write-Host $msg -ForegroundColor Red }  }
function WriteDarkRed($msg, $noNewLine = $false)  {  if($noNewLine) { Write-Host $msg -ForegroundColor DarkRed -NoNewline } else { Write-Host $msg -ForegroundColor DarkRed }  }
function WriteYellow($msg, $noNewLine = $false)   {  if($noNewLine) { Write-Host $msg -ForegroundColor Yellow -NoNewline } else { Write-Host $msg -ForegroundColor Yellow }  }
function WriteCyan($msg, $noNewLine)              {  if($noNewLine) { Write-Host $msg -ForegroundColor Cyan -NoNewline } else { Write-Host $msg -ForegroundColor Cyan }  }
function WriteGreen($msg, $noNewLine)             {  if($noNewLine) { Write-Host $msg -ForegroundColor Green -NoNewline } else { Write-Host $msg -ForegroundColor Green }  }
function WriteDarkGreen($msg, $noNewLine = $false){  if($noNewLine) { Write-Host $msg -ForegroundColor DarkGreen -NoNewline } else { Write-Host $msg -ForegroundColor DarkGreen }  }
function WriteGray($msg, $noNewLine = $false)     {  if($noNewLine) { Write-Host $msg -ForegroundColor Gray -NoNewline } else { Write-Host $msg -ForegroundColor Gray }  }
function WriteWhite($msg, $noNewLine = $false)    {  if($noNewLine) { Write-Host $msg -ForegroundColor White -NoNewline } else { Write-Host $msg -ForegroundColor White }  }

function TestPathSilently($dirPath, $returnPath = $false) { 
    $exists = Test-Path $dirPath -ErrorAction SilentlyContinue
    
    If (-not($returnPath)) { return $exists }
    if (-not($exists)) {  return $null  }
    
    return $dirPath
}
function IsFile($path) {
    if ([string]::IsNullOrEmpty($path) -OR -not(Test-Path $path -ErrorAction SilentlyContinue)) {
        Write-Host "Kozubenko.Utils:IsFile(`$path) has hit sanity check. `$path: $path"
        return $false
    }

    if (Test-Path -Path $path -PathType Leaf) {  return $true;  }
    else {
        return $false
    }
}
function IsDirectory($path) {
    if ([string]::IsNullOrEmpty($path) -OR -not(Test-Path $path -ErrorAction SilentlyContinue)) {
        Write-Host "Kozubenko.Utils:IsDirectory(`$path) has hit sanity check. `$path: $path"
        return $false
    }

    if (Test-Path -Path $path -PathType Container) {  return $true  }
    else {
        return $false
    }
}
function WriteErrorExit([string]$errorMsg) {
    WriteDarkRed $errorMsg
    WriteDarkRed "Exiting Script..."
    exit
}

function SetAliases($function, [Array]$aliases) {   # Throws exception if you try to call twice on same alias
    if ($function -eq $null -or $aliases -eq $null) {  return  }

    $ErrorActionPreference = "Stop"     # A relic of a past implementation. Want everything that can be thrown, thrown. Can likely remove in the future.
    foreach ($alias in $aliases) {
        Set-Alias -Name $alias -Value $function -Scope Global -Option Constant,AllScope -Force
    }
    $ErrorActionPreference = "Continue"
}