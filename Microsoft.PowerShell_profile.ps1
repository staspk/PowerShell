using module .\classes\FunctionRegistry.psm1
using module .\Kozubenko.Utils.psm1
using module .\Kozubenko.Bible.psm1
using module .\Kozubenko.Git.psm1
using module .\Kozubenko.Python.psm1
using module .\Kozubenko.Node.psm1
using module .\Kozubenko.Runtime.psm1
using module .\Kozubenko.IO.psm1

SetGlobal "PROFILE_DIR"  $(ParentDir($PROFILE))
SetGlobal "desktop"      "$HOME\Desktop"
SetGlobal "downloads"    "$HOME\Downloads"
SetGlobal "appdata"      "$HOME\AppData\Roaming"
SetGlobal "startup"      "$appdata\Microsoft\Windows\Start Menu\Programs\Startup"
SetGlobal "yt-dlp"       "$desktop\yt-dlp"
SetGlobal "cheats"       "$PROFILE_DIR\cheat-notes"
SetGlobal "notes"        "$PROFILE_DIR\cheat-notes"
class KozubenkoProfile {
    static [FunctionRegistry] GetFunctionRegistry() {
        return [FunctionRegistry]::new(
            "Kozubenko.Profile",
            @(
                "Open(`$path = 'PWD.Path')              -->   opens .\ or `$path in File Explorer",
                "Vs(`$path = 'PWD.Path')                -->   opens .\ or `$path in Visual Studio",
                "Vsc(`$path = 'PWD.Path')               -->   opens .\ or `$path in Visual Studio Code.",
                "Note(`$path = 'PWD.Path')              -->   opens .\ or `$path in Notepad++",
                "str_to_list(`$array, `$delimiter = ' ') -->   usage: str_to_list 'KJV', 'NKJV', 'RSV', 'NRSV', 'NASB' ';'"
            ));
    }
}
function Help($moduleName = $null) {
    $PrintModuleToConsoleScript = {
        param([FunctionRegistry]$module)
        
        PrintRed $module.moduleName
            foreach($func in $module.functions) {
                $funcName = $func.Split("(")[0]
                $insideParentheses = $($func.Split("(")[1]).Split(")")[0]
    
                PrintLiteRed "   $funcName" $false
                PrintLiteRed "(" $false
                PrintDarkGray "`e[3m$insideParentheses" $false
                PrintLiteRed ")" $false
    
                if($module.moduleName -ne "Kozubenko.MyRuntime") {      # hard coded fix. Kozubenko.MyRuntime does not have anything to the right side of -->
                    $rightOfParenthesesLeftFromArrow = $($func.Split(")")[1]).Split("-->")[0];
                    $funcExplanation = $func.Split("-->")[1];
    
                    PrintLiteRed "$rightOfParenthesesLeftFromArrow -->" $false
                    PrintWhiteRed "$funcExplanation" $false
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

function Open($path = $PWD.Path) {
    if (-not(Test-Path $path)) { PrintRed "`$path is not a valid path. `$path == $path";  RETURN; }

    $path = (Resolve-Path $path).Path

    if (IsFile($path)) {
        $extension = [System.IO.Path]::GetExtension($path)
        if($extension -eq ".html") {  Start-Process msedge "file:///$path"  }
        else {
            explorer.exe "$([System.IO.Path]::GetDirectoryName($path))"
        }
    }
    else {  explorer.exe $path  }
}
function Vs($path = $PWD.Path) {`
    if ($path -eq "..") {  $path = "$PWD\.."  }
    if (-not(Test-Path $path)) {  PrintRed "`$path is not a valid path. `$path == $path";  RETURN;  }
    if (IsFile($path)) {  $path = ParentDir($path)  }
    
    $solution = Get-ChildItem -Path $RootDirectory -Filter "*.sln"
    if ($solution.Count -eq 1) {
        Invoke-Item $solution.FullName
    } else {
        PrintRed "Directory must have a .sln file. .sln count: $($solutions.Count)"
    }
}
function Vsc($path = $PWD.Path) {
    if ($path -eq "..") {  $path = "$PWD\.."  }
    if (-not(Test-Path $path)) {  PrintRed "`$path is not a valid path. `$path == $path";  RETURN;  }
    if (IsFile $path) {  $path = ParentDir($path)  }
    code $path
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
function list() {
    Clear-Host
    $global:MyRuntime.LoadInGlobals($null)
}
function profile() {
    vsc $profile
}

function Find($filename) {
    $path = $($PWD.Path)
    Get-ChildItem -Path $path -Filter $filename -Recurse -File -ErrorAction SilentlyContinue
    # $searchResults | Format-List *
}
function Search($string, $all_file_types = $false) {
    if($all_file_types) {
        Get-ChildItem -Path . -File -Recurse | Select-String -Pattern $string
    }
    else {
        Get-ChildItem -Path . -Filter *.txt -Recurse | Select-String -Pattern $string
    }
}

function OnOpen() {
    Write-Host "`e]0;PowerShell $($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor).$($PSVersionTable.PSVersion.Patch)`a"
    
    $global:MyRuntime = [MyRuntime]::new()
    $global:MyRuntime.AddModules(@(
        # [KozubenkoBible]::GetFunctionRegistry(),
        # [KozubenkoVideo]::GetFunctionRegistry(),
        [KozubenkoIO]::GetFunctionRegistry(),
        [KozubenkoProfile]::GetFunctionRegistry(),
        [KozubenkoGit]::GetFunctionRegistry(),
        [KozubenkoPython]::GetFunctionRegistry(),
        [KozubenkoNode]::GetFunctionRegistry()
    ));

    SetAliases Restart @("re", "res")
    SetAliases Clear-Host  @("z", "zz", "zzz")
    SetAliases "C:\Program Files\Notepad++\notepad++.exe" @("note")

    Set-PSReadLineKeyHandler -Key Alt+1           -Description "Print `$cheats files"   -ScriptBlock {  Clear-Host; Get-ChildItem -Path $global:cheats | ForEach-Object { PrintRed $_.Name }; ConsoleInsert("$cheats\")  }
    Set-PSReadLineKeyHandler -Key Alt+Backspace   -Description "Delete Line"             -ScriptBlock {  ConsoleDeleteInput       }
    Set-PSReadLineKeyHandler -Key Alt+LeftArrow   -Description "Move to Start of Line"    -ScriptBlock {  ConsoleMoveToStartofLine }
    Set-PSReadLineKeyHandler -Key Alt+RightArrow  -Description "Move to End of Line"       -ScriptBlock {   ConsoleMoveToEndofLine  }
    Set-PSReadLineKeyHandler -Key Ctrl+z          -Description "Clear Screen"               -ScriptBlock {   ClearTerminal           }
    Set-PSReadLineKeyHandler -Key Enter           -Description "Runtime.HandleConsoleInput"  -ScriptBlock {
        $buffer = $null; $cursor = 0;
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$buffer, [ref]$cursor);
        switch ($buffer) {
        "" {
            $global:MyRuntime.HandleDefaultAction(); break;
        }
        ".." {
            ConsoleDeleteInput; ConsoleAcceptLine; Set-Location ".."; break;
        }
        default {  [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()  }}
    }
}
OnOpen



function NodeRun([string]$server = "C:\Users\stasp\Desktop\C#\Shared.Kozubenko\NodeJS\server.js", [string]$client = "C:\Users\stasp\Desktop\C#\Shared.Kozubenko\NodeJS\client.js") {
    Clear-Host
    # Set-Location $(ParentDir($server))
    Start-Process pwsh -ArgumentList '-NoExit', '-Command', "Clear-Host; node $client"
    node $server
}


function StartCoreServer($projectDir = "C:\Users\stasp\Desktop\C#\Shared.Kozubenko\TcpServer") {
    Set-Location $projectDir
    dotnet run
}




function Docstring-Example($Param1) {
    <#
    .SYNOPSIS
    I have an explanation and this is it.
    #>
}