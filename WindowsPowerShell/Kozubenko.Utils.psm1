function WriteRed($msg, $noNewLine = $false)      {  if($noNewLine) { Write-Host $msg -ForegroundColor Red -NoNewline } else { Write-Host $msg -ForegroundColor Red }  }
function WriteDarkRed($msg, $noNewLine = $false)  {  if($noNewLine) { Write-Host $msg -ForegroundColor DarkRed -NoNewline } else { Write-Host $msg -ForegroundColor DarkRed }  }
function WriteYellow($msg, $noNewLine = $false)   {  if($noNewLine) { Write-Host $msg -ForegroundColor Yellow -NoNewline } else { Write-Host $msg -ForegroundColor Yellow }  }
function WriteCyan($msg, $noNewLine)              {  if($noNewLine) { Write-Host $msg -ForegroundColor Cyan -NoNewline } else { Write-Host $msg -ForegroundColor Cyan }  }
function WriteGreen($msg, $noNewLine)             {  if($noNewLine) { Write-Host $msg -ForegroundColor Green -NoNewline } else { Write-Host $msg -ForegroundColor Green }  }
function WriteDarkGreen($msg, $noNewLine = $false){  if($noNewLine) { Write-Host $msg -ForegroundColor DarkGreen -NoNewline } else { Write-Host $msg -ForegroundColor DarkGreen }  }
function WriteGray($msg, $noNewLine = $false)     {  if($noNewLine) { Write-Host $msg -ForegroundColor Gray -NoNewline } else { Write-Host $msg -ForegroundColor Gray }  }
function WriteWhite($msg, $noNewLine = $false)    {  if($noNewLine) { Write-Host $msg -ForegroundColor White -NoNewline } else { Write-Host $msg -ForegroundColor White }  }
function WriteErrorExit([string]$errorMsg) {
    WriteDarkRed $errorMsg
    WriteDarkRed "Exiting Script..."
    exit
}
function TestPathSilently($dirPath, $returnPath = $false) { 
    $exists = Test-Path $dirPath -ErrorAction SilentlyContinue
    
    If (-not($returnPath)) { return $exists }
    if (-not($exists)) {  return $null  }
    
    return $dirPath
}
function IsFile($path) {
    if ([string]::IsNullOrEmpty($path) -OR -not(Test-Path $path -ErrorAction SilentlyContinue)) {  return $false  }
    if (Test-Path -Path $path -PathType Leaf) {  return $true  }
}
function SetAliases($function, [Array]$aliases) {
    if ([string]::IsNullOrEmpty($function) -or [string]::IsNullOrEmpty($aliases)) {  return  }

    foreach($alias in $aliases) {
        try {
            $ErrorActionPreference = "Stop"     # Needs to be set so the possible error throws
            Set-Alias -Name $alias -Value $function -Scope Global
        }
        catch {
            if ($_.FullyQualifiedErrorId -eq "AliasAllScopeOptionCannotBeRemoved,Microsoft.PowerShell.Commands.SetAliasCommand") {
                $isAnAlias = Get-Alias $alias
                if($isAnAlias) {
                    Set-Alias $alias $function -Force -Scope Global -Option 'Constant','AllScope' }
            }
            else {  throw $_  }
        }
        finally {  $ErrorActionPreference = "Continue"  }
    }
}