function TestPathSilently($dirPath, $returnPath = $false) { 
    $exists = Test-Path $dirPath -ErrorAction SilentlyContinue
    
    If (-not($returnPath)) { return $exists }
    Else {
        if (-not($exists)) {  return $null  }
        return $dirPath
    }
}