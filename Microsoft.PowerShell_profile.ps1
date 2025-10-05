using module .\classes\FunctionRegistry.psm1
using module .\Kozubenko.Utils.psm1
using module .\Kozubenko.OS.psm1
using module .\Kozubenko.Git.psm1
using module .\Kozubenko.Python.psm1
using module .\Kozubenko.Node.psm1
using module .\Kozubenko.Bible.psm1
using module .\Kozubenko.Runtime.psm1


$global:stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

SetGlobal "PROFILE_DIR"  $(ParentDir $PROFILE)
SetGlobal "desktop"      "$HOME\Desktop"
SetGlobal "downloads"    "$HOME\Downloads"
SetGlobal "appdata"      "$HOME\AppData\Roaming"
SetGlobal "startup"      "$appdata\Microsoft\Windows\Start Menu\Programs\Startup"
SetGlobal "yt-dlp"       "$desktop\yt-dlp"
SetGlobal "cheats"       "$PROFILE_DIR\cheat-notes"
SetGlobal "notes"        "$PROFILE_DIR\cheat-notes"
SetGlobal "pwsh_history_file" $((Get-PSReadLineOption).HistorySavePath)

class KozubenkoProfile {
    static [FunctionRegistry] GetFunctionRegistry() {
        return [FunctionRegistry]::new(
            "Kozubenko.Profile",
            @(
                "Open(`$path = 'PWD.Path')              -->   opens .\ or `$path in File Explorer",
                "Vs(`$path = 'PWD.Path')                -->   opens .\ or `$path in Visual Studio",
                "Vsc(`$path = 'PWD.Path')               -->   opens .\ or `$path in Visual Studio Code.",
                "Note(`$path = 'PWD.Path')              -->   opens .\ or `$path in Notepad++",
                "loadTime()                             -->   print profile loadTime in ms (excludes imports)",
                "profile()                              -->   vsc `$(ParentDir `$PROFILE)",
                "shortcuts()                            -->   see keyboard shortcuts"
            ));
    }
}

function Open($path = $PWD.Path) {
    if (-not(Test-Path $path)) { PrintRed "`$path does not exist. `$path: $path`n";  RETURN; }

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
function Vs($path = $PWD.Path) {
    if (-not(Test-Path $path)) {  PrintRed "`$path is not a valid path. `$path == $path`n";  RETURN;  }
    if (IsFile($path)) {  $path = ParentDir($path)  }
    
    $solution = Get-ChildItem -Path $RootDirectory -Filter "*.sln"
    if ($solution.Count -eq 1) {
        Invoke-Item $solution.FullName
    } else {
        PrintRed "Directory must have a .sln file. .sln count: $($solutions.Count)`n"
    }
}
function Vsc($path = $PWD.Path) {
    if (-not(Test-Path $path)) {  PrintRed "`$path is not a valid path. `$path == $path";  RETURN;  }
    if (IsFile($path)) {  $path = ParentDir($path)  }
    
    code $path
}

function loadTime() {
    PrintRed "$($global:stopwatch.Elapsed.TotalMilliseconds.ToString("F3"))ms"
}
function profile() {
    vsc $global:PROFILE_DIR
}
function shortcuts() {
    Get-PSReadLineKeyHandler
}


function OnOpen() {
    TerminalTitleBar "PowerShell $($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor).$($PSVersionTable.PSVersion.Patch)"

    $global:MyRuntime = [MyRuntime]::new()
    $global:MyRuntime.AddModules(@(
        [MyRuntime_FunctionRegistry]::Get(),
        # [KozubenkoBible]::GetFunctionRegistry(),
        # [KozubenkoVideo]::GetFunctionRegistry(),
        [KozubenkoOS]::GetFunctionRegistry(),
        [KozubenkoProfile]::GetFunctionRegistry(),
        [KozubenkoGit]::GetFunctionRegistry(),
        [KozubenkoPython]::GetFunctionRegistry(),
        [KozubenkoNode]::GetFunctionRegistry()
    ));

    SetAliases Restart @("re", "res")
    SetAliases Clear-Host  @("z", "zz", "zzz")
    SetAliases "C:\Program Files\Notepad++\notepad++.exe" @("note")

    Set-PSReadLineKeyHandler -Key Alt+1           -Description "List cheat-notes"                   -ScriptBlock {  Clear-Host; Get-ChildItem -Path $global:cheats | ForEach-Object { PrintLiteRed $_.Name -NewLine }; ConsoleInsert("$cheats\")  }
    Set-PSReadLineKeyHandler -Key Alt+Backspace   -Description "Delete Line"                        -ScriptBlock {  ConsoleDeleteInput  }
    Set-PSReadLineKeyHandler -Key Alt+LeftArrow   -Description "Move to Start of Line"              -ScriptBlock {  ConsoleMoveToStartofLine  }
    Set-PSReadLineKeyHandler -Key Alt+RightArrow  -Description "Move to End of Line"                -ScriptBlock {  ConsoleMoveToEndofLine  }
    Set-PSReadLineKeyHandler -Key Ctrl+z          -Description "Clear Screen"                       -ScriptBlock {  ClearTerminal  }
    Set-PSReadLineKeyHandler -Key UpArrow         -Description "Runtime.OverridePreviousHistory()"  -ScriptBlock {  $global:MyRuntime.OverridePreviousHistory()  }
    Set-PSReadLineKeyHandler -Key DownArrow       -Description "Runtime.CycleCommands()"            -ScriptBlock {  $global:MyRuntime.CycleCommands()  }
    Set-PSReadLineKeyHandler -Key Enter           -Description "Runtime.RunDefaultCommand()"        -ScriptBlock {
        $buffer = $null; $cursor = 0;
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$buffer, [ref]$cursor);

        $global:MyRuntime.history_depth = 0

        if($buffer.StartsWith("..")) {
            ConsoleDeleteInput; ConsoleInsert "cd $buffer"; ConsoleAcceptLine;
            return;
        }

        if($buffer -eq "") {
            $global:MyRuntime.RunDefaultCommand(); RETURN;  }

        ConsoleAcceptLine
    }
}
# $sw = [System.Diagnostics.Stopwatch]::StartNew()
OnOpen

$global:stopwatch.Stop()




function Docstring-Example($param1) {
    <# 
    .SYNOPSIS
    Returns combined path. Parent directory guaranteed to exist after call, file not guaranteed.

    Will throw if:
        - $paths.Count < 2

    PS > $lines = [Kozubenko.Utils.List]::CreateList($FILE)
    Returns:
        [string] || throws
    #>
}