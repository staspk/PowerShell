using module .\classes\FunctionRegistry.psm1
using module .\Kozubenko.Utils.psm1
using module .\Kozubenko.Git.psm1
using module .\Kozubenko.Python.psm1
using module .\Kozubenko.Node.psm1
using module .\Kozubenko.Runtime.psm1
using module .\Kozubenko.IO.psm1

SetGlobal "PROFILE_DIR"  $(ParentDir($PROFILE))
SetGlobal "GLOBALS"      "$PROFILE_DIR\globals"
SetGlobal "cheats"       "$PROFILE_DIR\cheat-notes"
SetGlobal "roaming"      "$HOME\AppData\Roaming"
SetGlobal "desktop"      "$HOME\Desktop"
class KozubenkoProfile {   
    static [FunctionRegistry] GetFunctionRegistry() {
        return [FunctionRegistry]::new(
            "Kozubenko.Profile",
            @(
                "Restart()                             -->   restarts Terminal. alias: re",    
                "Open(`$path = 'PWD.Path')              -->   opens .\ or `$path in File Explorer",
                "VsCode(`$path = 'PWD.Path')            -->   opens .\ or `$path in Visual Studio Code. alias: vsc",
                "Note(`$path = 'PWD.Path')              -->   opens .\ or `$path in Notepad++",
                "Bible(`$passage)                       -->   `$passage == 'John:10'; opens in BibleGateway in 5 translations",
                "UnixToMyTime(`$timestamp)              -->   self-explanatory",
                "vtt_to_srt(`$file)                     -->   convert subtitles from format .vtt to .srt",
                "webm_to_mp4(`$file)                    -->   convert webm to mp4 file, crt==18 (visually lossless)"
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
function Restart {                                         # try this version for a while...perhaps it will resolve the edge case of not always closing original window
    $oldPid = $PID
    PrintRed "`$oldPid==$oldPid"
    Invoke-Item "$global:pshome\pwsh.exe"
    
    PrintRed "before exit command"
    [System.Environment]::Exit(0)
    PrintRed "after exit command"
    try {
        
        PrintRed "before stop-process command"
        Stop-Process -Id $oldPid# -ErrorAction SilentlyContinue
        PrintRed "after stop-process command"
    }
    catch{}
}

function Open($path = $PWD.Path) {   # PUBLIC  -->  Opens In File Explorer
    if (-not(TestPathSilently($path))) { PrintRed "`$path is not a valid path. `$path == $path";  RETURN; }

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
function VsCode($path = $PWD.Path) {    # PUBLIC  -->  Opens in Visual Studio Code
    if ($path -eq "..") {
        $path = "$PWD.Path\.."
    }

    if (-not(TestPathSilently($path))) { PrintRed "`$path is not a valid path. `$path == $path";  RETURN; }

    if (IsFile($path)) {  $containingDir = [System.IO.Path]::GetDirectoryName($path); code $containingDir;  RETURN; }
    else { code $path }
}
function Bible($string) {       # BIBLE John:10
    $array = $string.Split(":")
    
    if($array.Count -ne 2) {
        PrintRed "Bible(`$input) => input must follow format: Matthew:10"
        RETURN
    }

    $version = "kjv;nasb;rsv;rusv;nrt"

    Start-Process microsoft-edge:"https://www.biblegateway.com/passage/?search=$($array[0])$($array[1])&version=$version" -WindowStyle maximized
}
function UnixToMyTime($timestamp) {
    $dateTimeUtc = [System.DateTimeOffset]::FromUnixTimeSeconds($timestamp).DateTime

    $dateTimeLocal = $dateTimeUtc.ToLocalTime()

    PrintCyan $dateTimeLocal
}

function vtt_to_srt($file) {
    if (-not(Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
        PrintRed "ffmpeg library required for function."
        RETURN;
    }

    $new_file = ""
    if($file.Substring($file.Length - 4) -eq ".vtt") {  $new_file = "$($file.Substring(0, $file.Length - 4)).srt"  }
    else {$new_file = "$file.srt"}

    PrintGreen "output: $new_file"

    ffmpeg -i "$file" -c:s subrip "$new_file" -loglevel quiet
}
function webm_to_mp4($file) {
    if (-not(Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
        PrintRed "ffmpeg library required for function."
        RETURN;
    }
    
    $new_file = ""
    if($file.Substring($file.Length - 5) -eq ".webm") {  $new_file = "$($file.Substring(0, $file.Length - 5)).mp4"  }
    else {$new_file = "$file.mp4"}

    ffmpeg -i "$file" -c:v libx264 -crf 18 -preset medium "$new_file"
}

function OnOpen() {
    $global:MyRuntime = [MyRuntime]::new($global:GLOBALS);

    $global:MyRuntime.AddModules(@(
        [KozubenkoIO]::GetFunctionRegistry(),
        [KozubenkoProfile]::GetFunctionRegistry(),
        [KozubenkoGit]::GetFunctionRegistry(),
        [KozubenkoPython]::GetFunctionRegistry(),
        [KozubenkoNode]::GetFunctionRegistry()
    ));

    SetAliases VsCode @("vsc")
    SetAliases Restart @("re", "res")
    SetAliases Clear-Host  @("z", "zz", "zzz")
    SetAliases "C:\Program Files\Notepad++\notepad++.exe" @("note")

    Set-PSReadLineKeyHandler -Key Alt+1           -Description "Print `$cheats files"    -ScriptBlock {  Clear-Host; Get-ChildItem -Path $global:cheats | ForEach-Object { PrintRed $_.Name }; ConsoleInsert("$cheats\")  }
    Set-PSReadLineKeyHandler -Key Alt+Backspace   -Description "Delete Line"             -ScriptBlock {  ConsoleDeleteInput  }
    Set-PSReadLineKeyHandler -Key Alt+LeftArrow   -Description "Move to Start of Line"   -ScriptBlock {  ConsoleMoveToStartofLine  }
    Set-PSReadLineKeyHandler -Key Alt+RightArrow  -Description "Move to End of Line"     -ScriptBlock {  ConsoleMoveToEndofLine  }
    Set-PSReadLineKeyHandler -Key Ctrl+z          -Description "Clear Screen"            -ScriptBlock {  ClearTerminal  } 
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

function profile {
    vsc $profile
}