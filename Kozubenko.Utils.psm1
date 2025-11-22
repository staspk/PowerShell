<#
---------------------------------------------
    GLOSSARY
        Color Definitions
        IsAdmin()
        List Class Util
        Directory/File/ResolvePath Utils
        Typing Utilities
        Path/File/Directory Utilities
        Terminal Utilities
        String Utilities
        Write/Print Utilities
        Possible Future Fossil Records - Vestigial Utilities
----------------------------------------------
#>


$WhiteRed = $PSStyle.Foreground.FromRgb(255, 196, 201);
$LiteRed  = $PSStyle.Foreground.FromRgb(223, 96, 107);
$LiteGreen = $PSStyle.Foreground.FromRgb(96, 223, 107);


function IsAdmin() {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

<#
---------------------------------------------
    List Class Util
----------------------------------------------
#>
class List {
    <#
    .SYNOPSIS
    Creates an easily mutable list from a file (each item represents a line). 
    
    Note: implementation coerces Get-Content return value to string[]. See differences in runtime return values by debugging:
        .\tests\Get-Content.Test.ps1
        .\tests\Kozubenko.Utils.List.Test.ps1
    
    PS > $lines = [Kozubenko.Utils.List]::FromFile($file)
    Returns:
        [System.Collections.Generic.List[string]] || $null - if $path does not exist
    #>
    static [System.Collections.Generic.List[string]] FromFile([string]$path) {
        if(-not(Test-Path $path)) {  return $null  }
        
        $array = [string[]]@(Get-Content $path)   # Using '@()' coerces Get-Content into an Array<string>. See test: .\tests\

        $lines = [System.Collections.Generic.List[string]]::new()
        $lines.AddRange($array)
        
        return $lines
    }

    <#
    .SYNOPSIS
    Overwrites a file with a list. 

    PS > [Kozubenko.Utils.List]::OverwriteFile($file, $lines)
    Result:
        Creates/overwrites $file with "", if $lines.Count = 0
        throws: System.IO.IOException [if file is locked/being used by another process]
    #>
    static [void] OverwriteFile([string]$path, [System.Collections.Generic.List[string]]$list) {
        $string = ""
        for ($i = 0; $i -lt $list.Count; $i++) {
            if($i -eq 0) {  $string += $list[$i]  }
            else {
                $string += $([Environment]::NewLine) + $list[$i]
            }
        }
        [System.IO.File]::WriteAllText($path, $string)
    }
}


<#
---------------------------------------------
    Directory/File/ResolvePath Utils
----------------------------------------------
#>
function Directory([Parameter(ValueFromRemainingArguments)] [string[]] $paths) {
    <# 
    .SYNOPSIS
    Returns combined, absolute path made up of $paths. Directory guaranteed to exist after call.

    :: Both lines are equivalent/legal syntax ::
    PS > $path = Directory $profile ".." sample_files
    PS > $path = Directory($profile, "..", "sample_files")
    Returns:
        [string] - combined, absolute path
    #>

    $result = $paths[0]
    for ($i = 1; $i -lt $paths.Count; $i++) {
        $result = Join-Path -Path $result -ChildPath $paths[$i]
    }

    $directory = [System.IO.Path]::GetFullPath($result)
    mkdir $directory -Force | Out-Null
    
    return $directory
}

function File([Parameter(ValueFromRemainingArguments)] [string[]] $paths) {
    <# 
    .SYNOPSIS
    Returns combined path. Parent directory guaranteed to exist after call, file ("leaf") is not created within File().

    Note: function implementation uses .NET, ie: use "$TestDrive" instead of "TestDrive:", else [System.IO.Path]::GetFullPath will ruin returned path.

    :: Both lines are equivalent/legal syntax ::
    PS > $path = File $env:TEMP sample_files test_file_0
    PS > $path = File($env:TEMP, "sample_files", "test_file_0")
    Returns:
        [string] || throws if $paths.Count < 2
    #>
    if ($paths.Count -lt 2) {
        throw "File(`$paths): `$paths.Count must be > 1. `$paths.Count: $($paths.Count). `$paths: $paths"
    }

    # if($paths[0] -eq )

    $result = $paths[0]
    for ($i = 1; $i -lt $paths.Count; $i++) {
        $result = Join-Path -Path $result -ChildPath $paths[$i]
    }

    $parent_dir = [System.IO.Path]::GetDirectoryName($result)
    mkdir $parent_dir -Force | Out-Null

    return [System.IO.Path]::GetFullPath($result)
}

function ResolvePath([string]$path, [switch]$Pwsh_Implementation) {     # Rough Draft for Function. Will implement when/if I actually need it. Overwritten below. 
    <# 
    .SYNOPSIS
    Returns an resolved, absolute path.

    Path does not have to exist with the default, .NET implementation. However, .NET does not know how to resolve special pwsh values like:
        TestDrive:\ [Pester temp drive] :: USE THE .NET equivalent: $TestDrive
        Env:\
        Registry
        other PSDrive's
    
    Default Implementation: uses .NET's [System.IO.Path]::GetFullPath($path)
        - Test-Path($path) can be True/False
        - .NET does not how to resolve TestDrive:

    PS > $lines = ResolvePath )
    Returns:
        [string] || throws
    #>
    if($Pwsh_Implementation) {
        
    }
    return [System.IO.Path]::GetFullPath($path)
}


<#
---------------------------------------------
    Typing Utilities
----------------------------------------------
#>
function GetType($var) {
    try {  return $var.GetType().Name  }
    catch {
        return "null"
    }
}
function ArrayAsDebugString($array_name, $array) {
    <# 
    .SYNOPSIS
    Returns array as a string.

    ArrayAsDebugString "itemsArray" @("item1", "item2", "item3")
    Returns:
        "itemsArray:[
           item1
           item2
           item3
        ]"
    #>
    if([string]::IsNullOrWhiteSpace($array_name) -OR -not($array -is [array])) {  throw "conditions not met for ArrayAsDebugString"  }
    $str = "$($array_name):[`n"
    foreach ($item in $array) {
        $str += "   $item`n"
    }
    $str += "]"
    return $str
}

function ConvertArrayToString([Array]$array) {
    <#
    .SYNOPSIS
    Converts @("one", "two", "three") -> "one,two,three"
    #>
    if(-not($array -is [array])) {  throw "ConvertArrayToString param is not an array. is: $(GetType $array)"  }

    $string = ""
    for ($i = 0; $i -lt $array.Count; $i++) {
        $string += $array[$i]
        if($i -lt $array.Count - 1) {
            $string += ","
        }
    }
    return $string
}
function SafeCoerceToArray($obj) {
    <#
    .SYNOPSIS
    Adds correct null-handling to PowerShell's @().

    $obj successfully tested as: Union<null,string,array>.
    #>
    if($null -eq $obj)   {  return @()  }
    if($obj -is [array]) {  return $obj  }
    return @($obj)
}


<#
---------------------------------------------
    Path/File/Directory Utilities
----------------------------------------------
#>
function ParentDir($path) {
    return [System.IO.Path]::GetDirectoryName($path)
}
function ResolvePath($path) {
    # $pwdItem = Get-Item $PWD
    # if ($pwdItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
    #     "PWD is a symlink/junction"
    # } else {
    #     return [System.IO.Path]::GetFullPath($path)
    # }
    return [System.IO.Path]::GetFullPath($path)
}
function IsFile($path) {
    if ([string]::IsNullOrEmpty($path) -OR -not(Test-Path $path -ErrorAction SilentlyContinue)) {
        # Write-Host "Kozubenko.Utils:IsFile(`$path) has hit sanity check. `$path: $path"
        return $false
    }

    if (Test-Path -Path $path -PathType Leaf) {  return $true;  }
    else {
        return $false
    }
}
function IsDirectory($path) {
    if ([string]::IsNullOrEmpty($path) -OR -not(Test-Path $path -ErrorAction SilentlyContinue)) {
        # Write-Host "Kozubenko.Utils:IsDirectory(`$path) has hit sanity check. `$path: $path"
        return $false
    }

    if (Test-Path -Path $path -PathType Container) {  return $true  }
    else {
        return $false
    }
}
function TestPath($path) { 
    $exists = Test-Path $path -ErrorAction SilentlyContinue
    
    if (-not($exists)) {  return $null  }
    else {
        return $path
    }
}


<#
---------------------------------------------
    Set-Variable/Set-Alias Utils
----------------------------------------------
#>
function SetAliasesFor($script_block, [Array]$aliases) {
    <# 
    .SYNOPSIS
    Uses `New-Item` under the hood, not `Set-Alias`

    PS > SetAliasesFor "git branch" @("b", "br", "bra")
    #>
    foreach ($alias in $aliases) {
        New-Item -Path "Function:\Global:$alias" -Value $script_block -Force -ErrorAction Stop | Out-Null
    }
}
function SetAliases($function, [Array]$aliases) {
    <# 
    .SYNOPSIS
    A QoL wrapper for Set-Alias

    throws: if alias already used
    #>
    if ($function -eq $null -or $aliases -eq $null) {  RETURN  }

    foreach ($alias in $aliases) {
        Set-Alias -Name $alias -Value $function -Scope Global -Option Constant,AllScope -Force
    }
}
function SetGlobal($varName, $value) {
    if($varName[0] -eq "$") {  $varName = $varName.Substring(1)  }
        
    Set-Variable -Name $varName -Value $value -Scope Global
}


<#
---------------------------------------------
    Terminal Utilities
----------------------------------------------
#>
function ClearTerminal {
    if(GetConsoleBufferState gt 0) {
        ConsoleDeleteInput
    }
    Clear-Host
    ConsoleAcceptLine
    ConsoleDeletePreviousLine
}
function GetConsoleBufferState() {
    <# 
    .SYNOPSIS
    Utility function for `[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$buffer, [ref]$cursor)`.
    If `$buffer` is "", will return `$null` instead (this allows ?? use).

    PS > $buffer, $cursor = GetConsoleBufferState
    Returns:
        @([String|Null], [Int32])
    #>
    $buffer = $null
    $cursor = 0
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$buffer, [ref]$cursor)
    if($buffer -eq "") { $buffer = $null }
    return @($buffer, $cursor)
}
function ConsoleInsert($text) {  [Microsoft.PowerShell.PSConsoleReadLine]::Insert($text)  }
function ConsoleAcceptLine() {  [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()  }
function ConsoleMoveToStartofLine {  [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition(0)  }
function ConsoleMoveToEndofLine {
    $buffer = $null
    $cursor = 0
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$buffer, [ref]$cursor)
    [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($buffer.Length)
}
function ConsoleDeleteInput {
    if ((GetConsoleBufferState)[1] -gt 0) {
        [Microsoft.PowerShell.PSConsoleReadLine]::BackwardDeleteInput()
    }
}
function ConsoleDeletePreviousLine {
    [console]::SetCursorPosition(0, [console]::CursorTop - 1)
    Write-Host (" " * [console]::WindowWidth)
    [console]::SetCursorPosition(0, [console]::CursorTop - 1)
}


<#
---------------------------------------------
    String Utilities
----------------------------------------------
#>
function find_text_between_characters([string]$string, [char]$char1, [char]$char2) {
    <# 
    .SYNOPSIS
    Returns:
        [string] text_between_chars (includes: "")
        || $null, when: {
            - $char2 found before $char1
            - both $char1/$char2 are not found by the end of function
        }
    #>
    $char1_found = $false; $char2_found = $false;
    $_string = ""
    
    for ($i = 0; $i -lt $string.Length; $i++) {
        if(-not($char1_found) -AND $char2_found) {
            return $null;
        }

        if($string[$i] -eq $char1) {  $char1_found = $true; continue  }
        if($string[$i] -eq $char2) {
            if(-not($char1_found)) {  return $null  }
            $char2_found = $true;
            break;
        }
        
        if($char1_found) {
            $_string += $string[$i]
        }
    }

    if($char1_found -AND $char2_found) {  return $_string  }
    return $null
}
function Capitalize($string) {
    $capitalizedStr = $string.Substring(0, 1).ToUpper()
    $capitalizedStr += $string.Substring(1, $string.Length - 1).ToLower()
    return $capitalizedStr
}


<#
---------------------------------------------
    Write/Print Utilities
----------------------------------------------
#>
function TerminalTitleBar($text) {  Write-Host "`e]0;$text`a"  -NoNewline }
function AddWhitespace($string, $amount) {
    for($i = $amount; $i -gt 0; $i--) {  $string += " "  }
    return $string
}

function PrintItalics($text, $color = $null)    {  if($color) {  Write-Host "`e[3m$text`e[0m" -ForegroundColor $color } else { Write-Host "`e[3m$text`e[0m" } }
function WriteItalics($text, $color = $null)    {  if($color) {  Write-Host "`e[3m$text`e[0m" -ForegroundColor $color -NoNewline } else { Write-Host "`e[3m$text`e[0m" -NoNewline } }
function Print($text)           {  Write-Host $text  }
function Write($text)           {  Write-Host $text -NoNewline  }
function PrintWhiteRed($text)   {  Write-Host ${WhiteRed}$text  }
function WriteWhiteRed($text)   {  Write-Host ${WhiteRed}$text -NoNewline  }
function PrintLiteRed($text)    {  Write-Host ${LiteRed}$text  }
function WriteLiteRed($text)    {  Write-Host ${LiteRed}$text -NoNewline  }
function PrintLiteGreen($text)  {  Write-Host ${LiteGreen}$text  }
function WriteLiteGreen($text)  {  Write-Host ${LiteGreen}$text  -NoNewline  }
function PrintRed($text)        {  Write-Host $text -ForegroundColor Red  }
function WriteRed($text)        {  Write-Host $text -ForegroundColor Red  -NoNewline  }
function PrintDarkRed($text)    {  Write-Host $text -ForegroundColor DarkRed  }
function WriteDarkRed($text)    {  Write-Host $text -ForegroundColor DarkRed  -NoNewline  }
function PrintYellow($text)     {  Write-Host $text -ForegroundColor Yellow  }
function WriteYellow($text)     {  Write-Host $text -ForegroundColor Yellow  -NoNewline  }
function PrintCyan($text)       {  Write-Host $text -ForegroundColor Cyan  }
function WriteCyan($text)       {  Write-Host $text -ForegroundColor Cyan  -NoNewline  }
function PrintDarkCyan($text)   {  Write-Host $text -ForegroundColor DarkCyan  }
function WriteDarkCyan($text)   {  Write-Host $text -ForegroundColor DarkCyan  -NoNewline  }
function PrintGreen($text)      {  Write-Host $text -ForegroundColor Green  }
function WriteGreen($text)      {  Write-Host $text -ForegroundColor Green  -NoNewline  }
function PrintDarkGreen($text)  {  Write-Host $text -ForegroundColor DarkGreen  }
function WriteDarkGreen($text)  {  Write-Host $text -ForegroundColor DarkGreen    }
function PrintDarkGray($text)   {  Write-Host $text -ForegroundColor DarkGray  }
function WriteDarkGray($text)   {  Write-Host $text -ForegroundColor DarkGray  -NoNewline  }
function PrintGray($text)       {  Write-Host $text -ForegroundColor Gray  }
function WriteGray($text)       {  Write-Host $text -ForegroundColor Gray  -NoNewline  }
function PrintWhite($text)      {  Write-Host $text -ForegroundColor White  }
function WriteWhite($text)      {  Write-Host $text -ForegroundColor White  -NoNewline  }



<#
------------------------------------------------------------
    Possible Future Fossil Records - Vestigial Utilities
------------------------------------------------------------
#>
function TurnOffSleepSettings([int]$time_in_hours = 0) {
    $screen_sleep = ((powercfg -query @(
    (powercfg -getactivescheme) -replace '^.+ \b([0-9a-f]+-[^ ]+).+', '$1'
        '7516b95f-f776-4464-8c53-06167f40cc99'
        '3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e'
    ))[-3] -replace '^.+: ') / 60

    $device_sleep  = ((powercfg -query @(
        (powercfg -getactivescheme) -replace '^.+ \b([0-9a-f]+-[^ ]+).+', '$1'
        '238c9fa8-0aad-41ed-83f4-97be242c8f20'
        '29f6c1db-86da-48c5-9fdb-f2b67b1f44da'
    ))[-3] -replace '^.+: ') / 60

    powercfg /change monitor-timeout-ac 5
    powercfg /change standby-timeout-ac 0

    if($time_in_hours -gt 0) {
        $temp_file = "$PROFILE_DIR\TurnSleepSettingsBackOn.ps1"
        $script = "powercfg /change monitor-timeout-ac $screen_sleep; powercfg /change standby-timeout-ac $device_sleep; Remove-Item $temp_file -Force; schtasks /delete /tn `"TurnSleepSettingsBackOn`" /f; exit;"
        $script | Out-File -FilePath $temp_file -Encoding UTF8

        $runTime = (Get-Date).AddMinutes($time_in_hours).ToString("HH:mm")
        $runDate = (Get-Date).AddMinutes($time_in_hours).ToString("MM/dd/yyyy")

        schtasks /create /tn "TurnSleepSettingsBackOn" `
            /tr "pwsh.exe -NoProfile -File $temp_file" `
            /sc once `
            /st $runTime /sd $runDate `
            /rl LIMITED `
            /f
    }
}

function RestoreClassicContextMenu([bool]$reverse = $false) {
	$guid = "{86CA1AA0-34AA-4E8B-A509-50C905BAE2A2}" 
	if(-not($reverse)) {
		New-Item -Path "HKCU:\Software\Classes\CLSID\" 		-Name $guid 					| Out-Null
		New-Item -Path "HKCU:\Software\Classes\CLSID\$guid" -Name InprocServer32 -Value "" 	| Out-Null
	}
	else {
		Remove-Item -Path "HKCU:\Software\Classes\CLSID\$guid" -Recurse -Force -ErrorAction SilentlyContinue
	}
    Stop-Process -Name explorer -Force -ErrorAction Ignore
}