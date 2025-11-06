<# 
    Some Test Results:

    $value: Union<string, array>
    @($value)[0]  => coercion/getting works, and is simpler than checking/handling if $value is str or array. 
        note: SafeCoerceToArray extends @() to handle $null, allowing for: Union<null, string, array>
#>

using module ..\Kozubenko.Utils.psm1
using module ..\Kozubenko.Runtime.psm1


$MyRuntime = [MyRuntime]::new($PSScriptRoot)
Remove-Item $MyRuntime._GLOBALS_FILE
Remove-Item $MyRuntime._COMMANDS_FILE

$MyRuntime.NewCommand(
    "C:\Users\stasp\Documents\PowerShell",
    "Invoke-Pester -Path .\tests\Get-Content.Test.ps1 -Output Detailed"
) 2>&1 4>&1 5>&1 6>&1 > $null

$MyRuntime.NewCommand(
    "C:\Users\stasp\Documents\PowerShell",
    "Invoke-Pester -Path Kozubenko.Runtime.Tests.ps1 -Output Detailed"
) 2>&1 4>&1 5>&1 6>&1 > $null

$commands = [MyRuntime]::LoadEnvFileIntoMemory($MyRuntime._COMMANDS_FILE)
$MyRuntime.commands = $commands

$MyRuntime.CycleCommands()
$MyRuntime.CycleCommands()
$MyRuntime.CycleCommands()

if($MyRuntime.history_depth -lt 3) {
    PrintGreen "Decrement_HistoryDepth Test Passed"
} else {
    PrintRed "Decrement_HistoryDepth Test Failed"
}


Remove-Item $MyRuntime._GLOBALS_FILE -Force 2>$null
Remove-Item $MyRuntime._COMMANDS_FILE -Force 2>$null



# $MyRuntime.NewCommand(
#     "C:\Users\stasp\Desktop\OS-Setup\Windows11\.vscode\vsc-augment",
#     ".\compile_import_into_vscode.ps1"
# )
