using module .\classes\FunctionRegistry.psm1
using module .\Kozubenko.Utils.psm1
class KozubenkoOS {   
    static [FunctionRegistry] GetFunctionRegistry() {
        return [FunctionRegistry]::new(
            "Kozubenko.OS",
            @(
                "AllSizes()                            -->   lists folders/files in current directory with their sizes (not on disk)",
                "FolderSizes()                         -->   lists folders in current directory with their sizes (not on disk)",
                "AddToEnvPath(`$path)                   -->   add to Windows user Env PATH. also: DeleteEnvPath(`$path), Path (lists)",
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

function AllSizes($startFolder = $PWD.Path) {
    $folderItems = Get-ChildItem $startFolder -Force

    $longestNameLen = 0
    $folderItemSizes = [System.Collections.Generic.OrderedDictionary[string, string]]::new()
    foreach ($item in $folderItems) {
        if ($item.PSIsContainer) {
            $subItems = Get-ChildItem $item.FullName -Recurse -Force | Where-Object { -not $_.PSIsContainer }
            $totalSize = ($subItems | Measure-Object -Property Length -Sum).Sum
        } else {  $totalSize = $item.Length  }

        $folderItemSizes.Add($item.name, "$("{0:N2}" -f ($totalSize / 1MB))MB")
        if($longestNameLen -lt $item.name.Length) {  $longestNameLen = $item.name.Length  }
    }

    foreach ($itemName in $folderItemSizes.Keys) {
        PrintGreen " $(AddWhitespace $itemName ($longestNameLen - $itemName.Length)) " $false
        PrintGray ":" $false
        PrintDarkRed " $($folderItemSizes[$itemName])"
    }
}
function FolderSizes($startFolder = $PWD.Path) {
    $folders = Get-ChildItem $startFolder | Where-Object {$_.PSIsContainer -eq $true}

    $longestNameLen = 0
    $folderSizes = [System.Collections.Generic.OrderedDictionary[string, string]]::new()
    foreach ($folder in $folders)
    {
        $subFolderItems = Get-ChildItem $folder.FullName -recurse -force | Where-Object {$_.PSIsContainer -eq $false} | Measure-Object -property Length -sum | Select-Object Sum
        
        $folderSizes.Add($folder.Name, "$("{0:N2}" -f ($subFolderItems.sum / 1MB))MB")
        if($longestNameLen -lt $folder.name.Length) {  $longestNameLen = $folder.name.Length  }
    }

    foreach ($folderName in $folderSizes.Keys) {
        PrintGreen " $(AddWhitespace $folderName ($longestNameLen - $folderName.Length)) " $false
        PrintGray ":" $false
        PrintDarkRed " $($folderSizes[$folderName])"
    }
}

# Adds to Windows PATH
function AddToEnvPath($path) {
    $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")

    $pathArray = $userPath.Split(";")

    if ($pathArray -contains $path) {  PrintGreen "The path '$path' is already in your PATH.";  RETURN;  }

    $newPath = ""
    foreach ($pathItem in $pathArray) {  $newPath += $pathItem + ";"  }

    [System.Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
}

function DeleteEnvPath($path) {     # example $pathItemToRemove: %USERPROFILE%\AppData\Local\Microsoft\WindowsApps
    $currentPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    $pathArray = $currentPath.Split(";")

    $newPath = ""
    for ($i = 0; $i -lt $pathArray.Count; $i++) {
        if ($pathArray[$i] -ne $path) {
            $newPath += "$($pathArray[$i]);"
        }
    }

    [System.Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
}

function ClearFolder($folder = ".\") {
    if (-not(IsDirectory $folder)) {  PrintDarkRed "Skipping ClearFolder, `$folder is not a directory: $folder";  RETURN;  }
    Get-ChildItem -Path $folder -Recurse | ForEach-Object {
        if ($_.PSIsContainer) {  $_.Delete($true)  }
        else {  $_.Delete()  }
    }
}

function LockFolder($folder) {
    if (-not(IsDirectory $folder)) {  PrintDarkRed "Skipping LockFolder, `$folder is not a directory: $folder";  RETURN;  }

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