#  1) Deletes contents and copy-pastes into: .\WindowsPowerShell, from: $Env:userprofile\Documents\WindowsPowerShell
#  2) Deletes contents and copy-pastes into: .\Powershell,        from: $Env:userprofile\Documents\Powershell
#  3) Asks for Commit Message, pushes to Remote


# Standard:                         .\saveProfilesPushToRemote.ps1 "Some Commit Message"
# Pull, don't Push:                 .\saveProfilesPushToRemote.ps1 -shouldPush $false
# Pushes, with "Automatic Push":    .\saveProfilesPushToRemote.ps1
param(
    $commitMessage,
    [bool] $shouldPush = $true
)

function DeleteDirContentsAndPasteInto($fromDir, $toDir) {
    $linesToDelete = 0;
    Get-ChildItem -Path $toDir -Recurse | ForEach-Object {
        if ($_.PSIsContainer) {  $_.Delete($true)  }
        else {
            $_.Delete()
        }
        Write-Host "Deleted: $_" -ForegroundColor Red; $linesToDelete++;
        Start-Sleep -Milliseconds 10
    }
    
    Copy-Item -Path "$fromDir\*" -Destination $toDir -Recurse
    Write-Host "`$Profile Contents COPY-PASTED to: $toDir" -ForegroundColor Green;  $linesToDelete++;
    Start-Sleep -Milliseconds 800
    
    
    for ($i = 1; $i -le $linesToDelete; $i++) {
        Start-Sleep -Milliseconds 5
        [console]::SetCursorPosition(0, [console]::CursorTop - 1)
        Write-Host (" " * [console]::WindowWidth)
        [console]::SetCursorPosition(0, [console]::CursorTop - 1)
    }
}

DeleteDirContentsAndPasteInto "$env:USERPROFILE\Documents\WindowsPowerShell" ".\WindowsPowerShell"
DeleteDirContentsAndPasteInto "$env:USERPROFILE\Documents\Powershell"        ".\Powershell"

if($shouldPush -eq $false) {
    return
}

if($commitMessage -eq $null -or $commitMessage -eq "") {
    $commitMessage = "Automatic Push"
}


git add .
git commit -a -m $commitMessage
git push