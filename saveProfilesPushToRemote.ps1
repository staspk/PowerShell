#  1) Deletes contents and copy-pastes into: .\WindowsPowerShell, from: $Env:userprofile\Documents\WindowsPowerShell
#  2) Deletes contents and copy-pastes into: .\Powershell,        from: $Env:userprofile\Documents\WindowsPowerShell
#  3) Asks for Commit Message, pushes to Remote

function DeleteContentsThenCopyPasteFromTo($profileDir, $scriptDir) {
    Get-ChildItem -Path $scriptDir -Recurse | ForEach-Object {
        $_.Delete()
        Write-Host "Deleted File: $_" -ForegroundColor Red
        Start-Sleep -Milliseconds 10
    }
    
    Copy-Item -Path "$profileDir\*" -Destination $scriptDir -Recurse
    Write-Host "`$Profile Contents COPY-PASTED to: $scriptDir" -ForegroundColor Green
    Start-Sleep -Milliseconds 800
    
    
    for ($i = 1; $i -le 5; $i++) {
        Start-Sleep -Milliseconds 5
        [console]::SetCursorPosition(0, [console]::CursorTop - 1)
        Write-Host (" " * [console]::WindowWidth)
        [console]::SetCursorPosition(0, [console]::CursorTop - 1)
    }
}

DeleteContentsThenCopyPasteFromTo "$env:USERPROFILE\Documents\WindowsPowerShell" ".\WindowsPowerShell"
DeleteContentsThenCopyPasteFromTo "$env:USERPROFILE\Documents\Powershell" ".\Powershell"
$commitMessage = Read-Host "Enter Commit Message"

git add .
git commit -a -m $commitMessage
git push