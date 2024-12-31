#  1) Deletes contents of $Env:userprofile\Documents\WindowsPowerShell and copy-pastes into it from: .\WindowsPowerShell
#  2) Deletes contents of $Env:userprofile\Documents\Powershell and copy-pastes into it from: .\Powershell

function DeleteDirContentsAndPasteInto($fromDir, $toDir) {
    Get-ChildItem -Path $toDir -Recurse | ForEach-Object {
        $_.Delete()
        Write-Host "Deleted File: $_" -ForegroundColor Red
        Start-Sleep -Milliseconds 10
    }

    Copy-Item -Path "$fromDir\*" -Destination $toDir -Recurse
    Write-Host "`$Profile COPY-PASTED into from: $fromDir" -ForegroundColor Green
    Start-Sleep -Milliseconds 800

    for ($i = 1; $i -le 5; $i++) {
        Start-Sleep -Milliseconds 5
        [console]::SetCursorPosition(0, [console]::CursorTop - 1)
        Write-Host (" " * [console]::WindowWidth)
        [console]::SetCursorPosition(0, [console]::CursorTop - 1)
    }
}

DeleteDirContentsAndPasteInto ".\WindowsPowerShell" "$env:USERPROFILE\Documents\WindowsPowerShell" 
DeleteDirContentsAndPasteInto ".\Powershell"        "$env:USERPROFILE\Documents\Powershell" 