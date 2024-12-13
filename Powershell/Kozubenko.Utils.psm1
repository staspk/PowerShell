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
function WriteErrorExit([string]$errorMsg) {
    WriteDarkRed $errorMsg
    WriteDarkRed "Exiting Script..."
    exit
}