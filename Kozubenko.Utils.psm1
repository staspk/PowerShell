$WhiteRed = $PSStyle.Foreground.FromRgb(255, 196, 201);
$LiteRed  = $PSStyle.Foreground.FromRgb(223, 96, 107);
$LiteGreen = $PSStyle.Foreground.FromRgb(96, 223, 107);





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

function ResolvePath([string]$path, [switch]$Pwsh_Implementation) {     # Unfinished Function. Will implement when/if i actually need it. Overwritten below. 
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

function GetType($var) {
    try {  return $var.GetType().Name  }
    catch {
        return "null"
    }
}
function AssertString($stringVarName, $string) {
    if(-not($stringVarName)) {
        throw [System.Management.Automation.RuntimeException]::new("AssertString second paramter required: `$stringVarName")
    }
    if([string]::IsNullOrEmpty($string)) {
        throw [System.Management.Automation.RuntimeException]::new("$stringVarName is Null or Empty")
    }
}


function IsAdmin() {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}


function ParentDir($path) {
    return [System.IO.Path]::GetDirectoryName($path)
}
function ResolvePath($path) {
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


function SetAliases($function, [Array]$aliases) {   # Throws exception if you try to set an alias on a keyword you already set an alias on
    if ($function -eq $null -or $aliases -eq $null) {  RETURN  }

    foreach ($alias in $aliases) {
        Set-Alias -Name $alias -Value $function -Scope Global -Option Constant,AllScope -Force
    }
}
function SetGlobal($varName, $value) {
    if($varName[0] -eq "$") {  $varName = $varName.Substring(1)  }
        
    Set-Variable -Name $varName -Value $value -Scope Global
}


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


function ClearTerminal {
    if(GetConsoleBufferState gt 0) {
        ConsoleDeleteInput
    }
    Clear-Host
    ConsoleAcceptLine
    ConsoleDeletePreviousLine
}
function GetConsoleBufferState() {
    $buffer = $null
    $cursor = 0
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$buffer, [ref]$cursor)
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


function Capitalize($string) {
    $capitalizedStr = $string.Substring(0, 1).ToUpper()
    $capitalizedStr += $string.Substring(1, $string.Length - 1).ToLower()
    return $capitalizedStr
}
function AddWhitespace($string, $amount) {
    for($i = $amount; $i -gt 0; $i--) {  $string += " "  }
    return $string
}

# Some explanation for TerminalTitleBar
function TerminalTitleBar($text) {  Write-Host "`e]0;$text`a"  -NoNewline }

function PrintItalics($text, $color = $null)    {  if($color) {  Write-Host "`e[3m$text`e[0m" -NoNewline -ForegroundColor $color  } else {  Write-Host "`e[3m$text`e[0m" -NoNewline  } }
function Print($text, [switch]$NewLine)         {  if ($NewLine) { Write-Host $text  } else { Write-Host $text -NoNewline } }
function PrintWhiteRed($text, [switch]$NewLine) {  if ($NewLine) { Write-Host ${WhiteRed}$text  } else { Write-Host ${WhiteRed}$text -NoNewline } }
function PrintLiteRed($text, [switch]$NewLine)  {  if ($NewLine) { Write-Host ${LiteRed}$text   } else { Write-Host ${LiteRed}$text -NoNewline  } }
function PrintLiteGreen($text, [switch]$NewLine){  if ($NewLine) { Write-Host ${LiteGreen}$text } else { Write-Host ${LiteGreen}$text -NoNewline } }
function PrintRed($text, [switch]$NewLine)      {  if ($NewLine) { Write-Host $text -ForegroundColor Red       } else { Write-Host $text -ForegroundColor Red -NoNewline      }  }
function PrintDarkRed($text, [switch]$NewLine)  {  if ($NewLine) { Write-Host $text -ForegroundColor DarkRed   } else { Write-Host $text -ForegroundColor DarkRed -NoNewline  }  }
function PrintYellow($text, [switch]$NewLine)   {  if ($NewLine) { Write-Host $text -ForegroundColor Yellow    } else { Write-Host $text -ForegroundColor Yellow -NoNewline   }  }
function PrintCyan($text, [switch]$NewLine)     {  if ($NewLine) { Write-Host $text -ForegroundColor Cyan      } else { Write-Host $text -ForegroundColor Cyan -NoNewline     }  }
function PrintDarkCyan($text, [switch]$NewLine) {  if ($NewLine) { Write-Host $text -ForegroundColor DarkCyan  } else { Write-Host $text -ForegroundColor DarkCyan -NoNewline }  }
function PrintGreen($text, [switch]$NewLine)    {  if ($NewLine) { Write-Host $text -ForegroundColor Green     } else { Write-Host $text -ForegroundColor Green -NoNewline    }  }
function PrintDarkGreen($text, [switch]$NewLine){  if ($NewLine) { Write-Host $text -ForegroundColor DarkGreen } else { Write-Host $text -ForegroundColor DarkGreen -NoNewline}  }
function PrintDarkGray($text, [switch]$NewLine) {  if ($NewLine) { Write-Host $text -ForegroundColor DarkGray  } else { Write-Host $text -ForegroundColor DarkGray -NoNewline }  }
function PrintGray($text, [switch]$NewLine)     {  if ($NewLine) { Write-Host $text -ForegroundColor Gray      } else { Write-Host $text -ForegroundColor Gray -NoNewline     }  }
function PrintWhite($text, [switch]$NewLine)    {  if ($NewLine) { Write-Host $text -ForegroundColor White     } else { Write-Host $text -ForegroundColor White -NoNewline    }  }
