using module .\classes\IRegistry.psm1
using module .\classes\HintRegistry.psm1
class KozubenkoOS : IRegistry {
    static [HintRegistry] GetRegistry() {
        return [HintRegistry]::new(
            "Kozubenko.OS",
            @(
                "AllSizes()                                    -->   lists folders/files in current directory with their sizes (not on disk)",
                "FolderSizes()                                 -->   lists folders in current directory with their sizes (not on disk)",
                "CountFiles()                                  -->   counts files from current dir, recursively",
                "LastModified()                                -->   recursively search `$PWD find the latest modifed file",
                "LockFolder(`$folder)                          -->   remove write access rules for 'Everyone'"
                "ClearFolder(`$folder = '.\')                  -->   recursively deletes contents of directory",
                "Find(`$filename)                              -->   recursively search for files, by filename",
                "Search(`$string, `$txt_files_only = `$false)  -->   recursively search file contents"
            ));
    }
}

function str_to_list([string]$array, $delimiter = " ") {
    <#
    .SYNOPSIS
    PS > str_to_list 'KJV', 'NKJV', 'RSV', 'NRSV', 'NASB' ';'
    Returns:
        KJV;NKJV;RSV;NRSV;NASB

    .DESCRIPTION
    Convert a list into a string.

    .PARAMETER array
    Expects a python-like list excluding brackets. Will be coerced into string.
    Example: 'KJV', 'NKJV', 'RSV', 'NRSV', 'NASB'

    .PARAMETER delimiter
    The character or string to insert between each element of the final joined output.
    Default: " "

    .EXAMPLE
    str_to_list 'KJV', 'NKJV', 'RSV', 'NRSV', 'NASB' ';'
    Returns:
        KJV;NKJV;RSV;NRSV;NASB
    #>
    $stringArray = $array -split '\s+'
    $result = $stringArray -join $delimiter
    return $result
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
        WriteGreen " $(AddWhitespace $itemName ($longestNameLen - $itemName.Length)) "
        WriteGray ":"
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
        WriteGreen " $(AddWhitespace $folderName ($longestNameLen - $folderName.Length)) "
        WriteGray ":"
        PrintDarkRed " $($folderSizes[$folderName])"
    }
}

function CountFiles() {
    (Get-ChildItem -File -Recurse | Measure-Object).Count
}

function LastModified() {
    $newestFile = $null
    $newestTime = [datetime]::MinValue

    foreach ($f in Get-ChildItem -Path $StartDir -File -Recurse -Force -ErrorAction SilentlyContinue) {
        if ($f.LastWriteTime -gt $newestTime) {
            $newestTime = $f.LastWriteTime
            $newestFile = $f
        }
    }

    if ($newestFile) {
        PrintRed $newestFile.LastWriteTime
        PrintLiteRed $newestFile.FullName
    }
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

function Find($filename) {
    <# 
    .SYNOPSIS
    Recursively search for files, by filename.
    #>
    $path = $($PWD.Path)
    Get-ChildItem -Path $path -Filter $filename -Recurse -File -ErrorAction SilentlyContinue
    # $searchResults | Format-List *
}
function Search($string, $txt_files_only = $false) {
    <# 
    .SYNOPSIS
    Recursively searches file contents for a specific string pattern.
    #>
    if($txt_files_only) {
        Get-ChildItem -Path $PWD -Filter *.txt -Recurse | Select-String -Pattern $string
    }
    else {
        Get-ChildItem -Path $PWD -File -Recurse | Select-String -Pattern $string
    }
}