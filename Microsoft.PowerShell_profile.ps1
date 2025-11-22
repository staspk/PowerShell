using module .\classes\IRegistry.psm1
using module .\classes\HintRegistry.psm1
using module .\Kozubenko.Assertions.psm1
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
SetGlobal "vscode"       "$env:APPDATA\Code\User"
class GLOBALS : IRegistry {
    static [HintRegistry] GetRegistry() {
        return [HintRegistry]::new(
            "GLOBALS",
            @(
                "PROFILE_DIR        -->  `$(ParentDir `$PROFILE)",
                "desktop            -->  `$HOME\Desktop",
                "downloads          -->  `$HOME\Downloads",
                "appdata            -->  `$HOME\AppData\Roaming",
                "startup            -->  `$appdata\Microsoft\Windows\Start Menu\Programs\Startup",
                "yt-dlp             -->  `$desktop\yt-dlp",
                "cheats             -->  `$PROFILE_DIR\cheat-notes",
                "notes              -->  `$PROFILE_DIR\notes",
                "pwsh_history_file  -->  `$((Get-PSReadLineOption).HistorySavePath)",
                "vscode             -->  `$env:APPDATA\Code\User"
            )
        );
    }
}

class KozubenkoProfile : IRegistry {
    static [HintRegistry] GetRegistry() {
        return [HintRegistry]::new(
            "Kozubenko.Profile",
            @(
                "Open(`$path = 'PWD.Path')              -->   opens .\ or `$path in File Explorer. Alias: O",
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
    if (-not(Test-Path $path)) { PrintRed "`$path does not exist. `$path: $path";  RETURN; }

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


function OnOpen($debug_mode = $false) {
    <#
    .SYNOPSIS
        $debug mode - truthy value passed in signifies to MyRuntime to not clear console after init.
    #>

    TerminalTitleBar "PowerShell $($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor).$($PSVersionTable.PSVersion.Patch)"

    if($debug_mode) {
        [MyRuntime]::ON_INIT_CLEAR_CONSOLE__FLAG = $false
    }
    $global:MyRuntime = [MyRuntime]::new()
    $global:MyRuntime.AddRegistrys(@(
        [GLOBALS]::GetRegistry(),
        [MyRuntime_FunctionRegistry]::GetRegistry(),
        # [KozubenkoBible]::GetRegistry(),
        # [KozubenkoVideo]::GetRegistry(),
        [KozubenkoOS]::GetRegistry(),
        [KozubenkoProfile]::GetRegistry(),
        [KozubenkoGit]::GetRegistry(),
        [KozubenkoPython]::GetRegistry(),
        [KozubenkoNode]::GetRegistry()
    ));

    SetAliases Open @("o")
    SetAliases Clear-Host  @("z", "zz", "zzz")
    SetAliases "C:\Program Files\Notepad++\notepad++.exe" @("note")

    Set-PSReadLineKeyHandler -Key Alt+1           -Description "List cheat-notes"                   -ScriptBlock {  Clear-Host; Get-ChildItem -Path $global:cheats | ForEach-Object { PrintLiteRed $_.Name }; ConsoleInsert("$cheats\")  }
    Set-PSReadLineKeyHandler -Key Alt+Backspace   -Description "Delete Line"                        -ScriptBlock {  ConsoleDeleteInput  }
    Set-PSReadLineKeyHandler -Key Alt+LeftArrow   -Description "Move to Start of Line"              -ScriptBlock {  ConsoleMoveToStartofLine  }
    Set-PSReadLineKeyHandler -Key Alt+RightArrow  -Description "Move to End of Line"                -ScriptBlock {  ConsoleMoveToEndofLine  }
    Set-PSReadLineKeyHandler -Key Alt+z           -Description "Cd .."                              -ScriptBlock {  Set-Location ..; ConsoleAcceptLine  }  
    Set-PSReadLineKeyHandler -Key Ctrl+z          -Description "Clear Screen"                       -ScriptBlock {  ClearTerminal  }
    Set-PSReadLineKeyHandler -Key Ctrl+.          -Description "Opens `$PWD in File Explorer"       -ScriptBlock {
        $buffer, $cursor = GetConsoleBufferState
        $path_to_open = $buffer ?? $PWD

        if (-not(Test-Path $path_to_open)) {  PrintRed "`$buffer is not a valid path. `$path_to_open: '$path_to_open'";  RETURN;  }

        if (IsFile $path_to_open) {  $path_to_open = ParentDir $path_to_open  }
        explorer.exe $path_to_open
    }
    Set-PSReadLineKeyHandler -Key UpArrow         -Description "Runtime.OverridePreviousHistory()"  -ScriptBlock {  $global:MyRuntime.OverridePreviousHistory()  }
    Set-PSReadLineKeyHandler -Key DownArrow       -Description "Runtime.CycleCommands()"            -ScriptBlock {  $global:MyRuntime.CycleCommands()  }
    Set-PSReadLineKeyHandler -Key Enter           -Description "EnterKeyHandler()"                  -ScriptBlock {
        $global:MyRuntime.history_depth = 0
        $buffer, $cursor = GetConsoleBufferState

        <# Git #>
        if($buffer -eq "br")          {  ConsoleDeleteInput; ConsoleInsert "git branch ";          RETURN; }
        if($buffer -eq "ch")          {  ConsoleDeleteInput; ConsoleInsert "git checkout ";        RETURN; }
        if($buffer -eq "st")          {  ConsoleDeleteInput; ConsoleInsert "git stash ";           RETURN; }
        if($buffer.StartsWith("re"))  {  ConsoleDeleteInput;
            $int = AssertInt $buffer.Split(" ")[1] "Correct Form: 're {int}'"
            ConsoleInsert "git rebase -i HEAD~$int";                           ConsoleAcceptLine;  RETURN;
        }

        elseif($buffer.StartsWith("..")) {
            Set-Location ..; ConsoleDeleteInput; ConsoleAcceptLine;  RETURN;
        }

        <# Else #>
        ConsoleAcceptLine
    }
}

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

<# 
    The other function form
#>
$check_trigger1 = {
    param(
        [int]$current_iteration,
        [int]$iteration_supposed_to_trigger
    )

    if($string[$i] -eq $char1) {

    }
}