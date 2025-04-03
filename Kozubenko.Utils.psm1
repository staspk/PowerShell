using module .\classes\FunctionRegistry.psm1

$WhiteRed = $PSStyle.Foreground.FromRgb(255, 196, 201);
$LiteRed = $PSStyle.Foreground.FromRgb(223, 96, 107);


function IsAdmin() {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function ResolvePath($path) {
    if (-not(TestPathSilently($path))) {  Write-Host "`$path is not a valid path. `$path == $path" -ForegroundColor Red;  RETURN;  }

    $path = (Resolve-Path $path).Path

    return $path
}

function TestPathSilently($dirPath, $returnPath = $false) { 
    $exists = Test-Path $dirPath -ErrorAction SilentlyContinue
    
    If (-not($returnPath)) { return $exists }
    if (-not($exists)) {  return $null  }
    
    return $dirPath
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
function ParentDir($path) {
    if(-not(TestPathSilently($path))) {  Write-Host "Skipping GetParent(`$path) since `$path does not exist: $path" -ForegroundColor Red;  RETURN;  }
    RETURN [System.IO.Path]::GetDirectoryName($path)
}

function WriteErrorExit([string]$errorMsg) {
    Write-Host $errorMsg -ForegroundColor DarkRed
    Write-Host "Exiting Script..." -ForegroundColor DarkRed
    exit
}

function SetAliases($function, [Array]$aliases) {   # Throws exception if you try to set an alias on a keyword you already set an alias on
    if ($function -eq $null -or $aliases -eq $null) {  RETURN  }

    foreach ($alias in $aliases) {
        Set-Alias -Name $alias -Value $function -Scope Global -Option Constant,AllScope -Force
    }
}
function SetGlobal($varName, $value) {
    if($varName[0] -eq "$") {
        $varName = $varName.Substring(1, $name.Length - 1 )
    }
        
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
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
}

function ClearTerminal {
    if(ConsoleInputTextLength gt 0) {
        ConsoleDeleteInput
    }
    Clear-Host
    ConsoleAcceptLine
    ConsoleDeletePreviousLine
}
function ConsoleInputTextLength() {
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
    if ((ConsoleInputTextLength)[1] -gt 0) {
        [Microsoft.PowerShell.PSConsoleReadLine]::BackwardDeleteInput()
    }
}
function ConsoleDeletePreviousLine {
    [console]::SetCursorPosition(0, [console]::CursorTop - 1)
    Write-Host (" " * [console]::WindowWidth)
    [console]::SetCursorPosition(0, [console]::CursorTop - 1)
}


function Print($text, $newLine = $true)         {  if($newLine) { Write-Host $text }         else {  Write-Host $text - -NoNewline  }  }
function PrintWhiteRed($text, $newLine = $true) {  if($newLine) { Write-Host ${WhiteRed}$text }     else { Write-Host ${WhiteRed}$text -NoNewline }  }
function PrintLiteRed($text, $newLine = $true)  {  if($newLine) { Write-Host ${LiteRed}$text  }      else { Write-Host ${LiteRed}$text -NoNewline }  }
function PrintRed($text, $newLine = $true)      {  if($newLine) { Write-Host $text -ForegroundColor Red }      else { Write-Host $text -ForegroundColor Red -NoNewline }        }
function PrintDarkRed($text, $newLine = $true)  {  if($newLine) { Write-Host $text -ForegroundColor DarkRed }   else { Write-Host $text -ForegroundColor DarkRed -NoNewline }    }
function PrintYellow($text, $newLine = $true)   {  if($newLine) { Write-Host $text -ForegroundColor Yellow }    else { Write-Host $text -ForegroundColor Yellow -NoNewline }     }
function PrintCyan($text, $newLine = $true)     {  if($newLine) { Write-Host $text -ForegroundColor Cyan }      else { Write-Host $text -ForegroundColor Cyan -NoNewline }       }
function PrintDarkCyan($text, $newLine = $true) {  if($newLine) { Write-Host $text -ForegroundColor DarkCyan }    else { Write-Host $text -ForegroundColor DarkCyan -NoNewline }      }
function PrintGreen($text, $newLine = $true)    {  if($newLine) { Write-Host $text -ForegroundColor Green }     else { Write-Host $text -ForegroundColor Green -NoNewline }      }
function PrintDarkGreen($text, $newLine = $true){  if($newLine) { Write-Host $text -ForegroundColor DarkGreen } else { Write-Host $text -ForegroundColor DarkGreen -NoNewline }  }
function PrintDarkGray($text, $newLine = $true) {  if($newLine) { Write-Host $text -ForegroundColor DarkGray }    else { Write-Host $text -ForegroundColor DarkGray -NoNewline }      }
function PrintGray($text, $newLine = $true)     {  if($newLine) { Write-Host $text -ForegroundColor Gray }      else { Write-Host $text -ForegroundColor Gray -NoNewline }       }
function PrintWhite($text, $newLine = $true)    {  if($newLine) { Write-Host $text -ForegroundColor White }    else { Write-Host $text -ForegroundColor White -NoNewline }      }


