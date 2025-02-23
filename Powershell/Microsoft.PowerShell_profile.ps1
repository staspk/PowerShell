using module .\classes\FunctionRegistry.psm1
using module .\Kozubenko.Utils.psm1
using module .\Kozubenko.Git.psm1
using module .\Kozubenko.Python.psm1
using module .\Kozubenko.Node.psm1
using module .\Kozubenko.Runtime.psm1


[String] $global:GLOBALS = "$(GetParentDir($PROFILE))\globals"

class KozubenkoProfile {   
    static [FunctionRegistry] GetFunctionRegistry() {
        return [FunctionRegistry]::new(
            "Kozubenko.Profile",
            @(
                "Restart()                         -->  restarts Terminal. alias: re",    
                "Open(`$path = 'PWD.Path')          -->  opens .\ or `$path in File Explorer",
                "VsCode(`$path = 'PWD.Path')        -->  opens .\ or `$path in Visual Studio Code. alias: vsc",
                "Note(`$path = 'PWD.Path')          -->  opens .\ or `$path in Notepad++",
                "ClearFolder(`$folderPath = '.\')   -->  recursively deletes contents of directory", 
                "DisplayFolderSizes()              -->  lists folders in current directory with their sizes (not on disk)",
                "Bible(`$passage)                   -->  `$passage == 'John:10'; opens in BibleGateway with 5 languages"
                # "StartCoreServer(`$projectDir)  -->  dotnet run"
            ));
    }
}
function Restart() {   # PUBLIC  -->  Restarts Terminal
    Invoke-Item $global:pshome\pwsh.exe; Exit
}
function Open($path = $PWD.Path) {   # PUBLIC  -->  Opens In File Explorer
    if (-not(TestPathSilently($path))) { WriteRed "`$path is not a valid path. `$path == $path";  Return; }
    if (IsFile($path)) {  explorer.exe "$([System.IO.Path]::GetDirectoryName($path))"  }
    else {  explorer.exe $path  }
}
function VsCode($path = $PWD.Path) {    # PUBLIC  -->  Opens in Visual Studio Code
    if ($path -eq "..") {
        $path = "$PWD.Path\.."
    }

    if (-not(TestPathSilently($path))) { WriteRed "`$path is not a valid path. `$path == $path";  Return; }

    if (IsFile($path)) {  $containingDir = [System.IO.Path]::GetDirectoryName($path); code $containingDir;  Return; }
    else { code $path }
}
function ClearFolder($folderPath = ".\") {
    if (-not(IsDirectory $folderPath)) {  WriteDarkRed "Skipping ClearFolder, `$folderPath is not a directory: $folderPath";  Return;  }
    Get-ChildItem -Path $folderPath -Recurse | ForEach-Object {
        if ($_.PSIsContainer) {  $_.Delete($true)  }
        else {  $_.Delete()  }
    }
}
function DisplayFolderSizes {
    $colItems = Get-ChildItem $startFolder | Where-Object {$_.PSIsContainer -eq $true} | Sort-Object
    foreach ($i in $colItems)
    {
        $subFolderItems = Get-ChildItem $i.FullName -recurse -force | Where-Object {$_.PSIsContainer -eq $false} | Measure-Object -property Length -sum | Select-Object Sum
        WriteGreen "$($i.Name)" $false; WriteGray " --> " $false; WriteDarkRed "$("{0:N2}" -f ($subFolderItems.sum / 1MB))MB"
    }
}
function Bible($string) {       # BIBLE John:10
    $array = $string.Split(":")
    
    if($array.Count -ne 2) {
        WriteRed "Bible(`$input) => input must follow format: Matthew:10"
        return
    }

    $version = "kjv;nasb;rsv;rusv;nrt"

    Start-Process microsoft-edge:"https://www.biblegateway.com/passage/?search=$($array[0])$($array[1])&version=$version" -WindowStyle maximized
}
function List($moduleName = $null) {
    $PrintModuleToConsoleScript = {
        param([FunctionRegistry]$module)
        
        WriteRed $module.moduleName
            foreach($func in $module.functions) {
                $funcName = $func.Split("(")[0]
                $insideParentheses = $($func.Split("(")[1]).Split(")")[0]
    
                WriteLiteRed "   $funcName" $false
                WriteLiteRed "(" $false
                WriteDarkGray "`e[3m$insideParentheses" $false
                WriteLiteRed ")" $false
    
                if($module.moduleName -ne "Kozubenko.MyRuntime") {      # hard coded fix. Kozubenko.MyRuntime does not have anything to the right side of -->
                    $rightOfParenthesesLeftFromArrow = $($func.Split(")")[1]).Split("-->")[0];
                    $funcExplanation = $func.Split("-->")[1];
    
                    WriteLiteRed "$rightOfParenthesesLeftFromArrow -->" $false
                    WriteWhiteRed "$funcExplanation" $false
                }
                Write-Host
            }
            Write-Host;
    }

    Clear-Host
    if($moduleName -eq $null) {
        foreach ($module in $global:MyRuntime.modules) {
            & $PrintModuleToConsoleScript -module $module
        } 
    }
    else {
        foreach ($module in $global:MyRuntime.modules) {
            if($module.moduleName -match $moduleName) {
                & $PrintModuleToConsoleScript -module $module
            }
        }
    }
}


function OnOpen() {
    $global:MyRuntime = [MyRuntime]::new($global:GLOBALS);

    $global:MyRuntime.AddModules(@(
        [KozubenkoProfile]::GetFunctionRegistry(),
        [KozubenkoGit]::GetFunctionRegistry(),
        [KozubenkoPython]::GetFunctionRegistry(),
        [KozubenkoNode]::GetFunctionRegistry()

    ));


    Set-PSReadLineKeyHandler -Key Ctrl+z -Description "Clear Screen" -ScriptBlock {
        Clear-Host
        [Microsoft.PowerShell.PSConsoleReadLine]::ClearScreen()
        [Microsoft.PowerShell.PSConsoleReadLine]::BackwardDeleteInput()
    }
    Set-PSReadLineKeyHandler -Key Alt+a -Description "Print `$cheats files" -ScriptBlock {
        Clear-Host
        Get-ChildItem -Path $global:cheats | ForEach-Object {
            WriteRed $_.Name
        }
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$cheats\")
    }
    Set-PSReadLineKeyHandler -Key Alt+Backspace -Description "Delete Line" -ScriptBlock {
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition(0)
        [Microsoft.PowerShell.PSConsoleReadLine]::KillLine()
    }
    
    
    SetAliases List @("help")
    SetAliases VsCode @("vsc")
    SetAliases Restart @("re", "res")
    SetAliases Clear-Host  @("z", "zz", "zzz")
    SetAliases "C:\Program Files\Notepad++\notepad++.exe" @("note")
}
OnOpen


function NodeRun([string]$server = "C:\Users\stasp\Desktop\C#\Shared.Kozubenko\NodeJS\server.js", [string]$client = "C:\Users\stasp\Desktop\C#\Shared.Kozubenko\NodeJS\client.js") {
    Clear-Host
    # Set-Location $(GetParentDir($server))
    Start-Process pwsh -ArgumentList '-NoExit', '-Command', "Clear-Host; node $client"
    node $server
}


# does not work
function StartCoreServer($projectDir = "C:\Users\stasp\Desktop\C#\Shared.Kozubenko\TcpServer") {
    Set-Location $projectDir
    dotnet run
}

