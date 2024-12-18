function WriteGreen ($msg) {  Write-Host $msg -ForegroundColor Green  }
function WriteRed ($msg) {  Write-Host $msg -ForegroundColor Red  }
function WriteDarkRed ($msg) {  Write-Host $msg -ForegroundColor DarkRed  }
function WriteCyan ($msg) {  Write-Host $msg -ForegroundColor Cyan  }
function WriteYellow ($msg) {  Write-Host $msg -ForegroundColor Yellow  }

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
function WriteErrorExit([string]$errorMsg) {
    WriteDarkRed $errorMsg
    WriteDarkRed "Exiting Script..."
    exit
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