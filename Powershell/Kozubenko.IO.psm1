using module .\classes\FunctionRegistry.psm1
class KozubenkoIO {   
    static [FunctionRegistry] GetFunctionRegistry() {
        return [FunctionRegistry]::new(
            "Kozubenko.IO",
            @(
                "AddToEnvPath(`$path)            -->   add to Windows user Env PATH. also: DeleteEnvPath(`$path), Path (lists)",
                "DisplayFolderSizes()                  -->   lists folders in current directory with their sizes (not on disk)",
                "ClearFolder(`$folder = '.\')           -->   recursively deletes contents of directory", 
                "LockFolder(`$folder)                   -->   remove write access rules for 'Everyone'"
            ));
    }
}

function Path {
    $windowsPath = [Environment]::GetEnvironmentVariable("PATH", "User")

    $pathArray = $windowsPath.Split(";") | ForEach-Object { $_.Trim() }

    foreach ($item in $pathArray) {
        Write-Host $item
    }
}

# Adds to Windows PATH
function AddToEnvPath($path) {
    $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")

    $pathArray = $userPath.Split(";")

    if ($pathArray -contains $newPathItem) {  WriteRed "The path '$newPathItem' is already in your PATH.";  RETURN;  }

    $newPath = ""
    foreach ($pathItem in $pathArray) {  $newPath += $pathItem + ";"  }
    $newPath += "$($newPathItem);"

    [System.Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
}

function DeleteEnvPath($path) {     # example $pathItemToRemove: %USERPROFILE%\AppData\Local\Microsoft\WindowsApps
    $currentPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    $pathArray = $currentPath.Split(";")

    $newPath = ""
    for ($i = 0; $i -lt $pathArray.Count; $i++) {
        if ($pathArray[$i] -ne $pathItemToRemove) {
            $newPath += "$($pathArray[$i]);"
        }
    }

    [System.Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
}


function DisplayFolderSizes {
    $colItems = Get-ChildItem $startFolder | Where-Object {$_.PSIsContainer -eq $true} | Sort-Object
    foreach ($i in $colItems)
    {
        $subFolderItems = Get-ChildItem $i.FullName -recurse -force | Where-Object {$_.PSIsContainer -eq $false} | Measure-Object -property Length -sum | Select-Object Sum
        WriteGreen "$($i.Name)" $false; WriteGray " --> " $false; WriteDarkRed "$("{0:N2}" -f ($subFolderItems.sum / 1MB))MB"
    }
}

function ClearFolder($folder = ".\") {
    if (-not(IsDirectory $folder)) {  WriteDarkRed "Skipping ClearFolder, `$folder is not a directory: $folder";  RETURN;  }
    Get-ChildItem -Path $folder -Recurse | ForEach-Object {
        if ($_.PSIsContainer) {  $_.Delete($true)  }
        else {  $_.Delete()  }
    }
}

function LockFolder($folder) {
    if (-not(IsDirectory $folder)) {  WriteDarkRed "Skipping LockFolder, `$folder is not a directory: $folder";  RETURN;  }

    $acl = Get-Acl -Path $folder

    $denyWriteRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        "Everyone", 
        "Write", 
        "ContainerInherit, ObjectInherit", 
        "None", 
        "Deny"
    )

    $acl.AddAccessRule($denyWriteRule)
    Set-Acl -Path $folder -AclObject $acl
    Write-Host "Write permissions for '$UserOrGroup' have been locked on folder: $folder"
}