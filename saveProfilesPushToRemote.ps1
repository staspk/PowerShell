#  1) Deletes contents and copy-pastes into: .\WindowsPowerShell, from: $Env:userprofile\Documents\WindowsPowerShell
#  2) Deletes contents and copy-pastes into: .\Powershell,        from: $Env:userprofile\Documents\Powershell
#  3) Asks for Commit Message, pushes to Remote

param(
    $commitMessage
)

function DeleteDirContentsAndPasteInto($fromDir, $toDir) {
    Get-ChildItem -Path $toDir -Recurse | ForEach-Object {
        $_.Delete()
        Write-Host "Deleted File: $_" -ForegroundColor Red
        Start-Sleep -Milliseconds 10
    }
    
    Copy-Item -Path "$fromDir\*" -Destination $toDir -Recurse
    Write-Host "`$Profile Contents COPY-PASTED to: $toDir" -ForegroundColor Green
    Start-Sleep -Milliseconds 800
    
    
    for ($i = 1; $i -le 5; $i++) {
        Start-Sleep -Milliseconds 5
        [console]::SetCursorPosition(0, [console]::CursorTop - 1)
        Write-Host (" " * [console]::WindowWidth)
        [console]::SetCursorPosition(0, [console]::CursorTop - 1)
    }
}

DeleteDirContentsAndPasteInto "$env:USERPROFILE\Documents\WindowsPowerShell" ".\WindowsPowerShell"
DeleteDirContentsAndPasteInto "$env:USERPROFILE\Documents\Powershell"        ".\Powershell"

if($path -eq "") {  $commitMessage = "Automatic Push"  }
if($path -eq $null) {
    $commitMessage = Read-Host "Enter Commit Message"
}

git add .
git commit -a -m $commitMessage
git push