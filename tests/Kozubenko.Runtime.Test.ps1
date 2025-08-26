using module ..\Kozubenko.Utils.psm1
using module ..\Kozubenko.Runtime.psm1



$MyRuntime = [MyRuntime]::new($PSScriptRoot)
Remove-Item $MyRuntime._GLOBALS_FILE
Remove-Item $MyRuntime._COMMANDS_FILE


$MyRuntime.NewCommand(
    "C:\Users\stasp\Documents\PowerShell",
    "Invoke-Pester -Path .\tests\Get-Content.Test.ps1 -Output Detailed"
)

$MyRuntime.NewCommand(
    "C:\Users\stasp\Documents\PowerShell",
    "Invoke-Pester -Path Kozubenko.Runtime.Tests.ps1 -Output Detailed"
)

$commands = [MyRuntime]::LoadEnvFileIntoMemory($MyRuntime._COMMANDS_FILE)


Write-Host



# $MyRuntime.NewCommand(
#     "C:\Users\stasp\Desktop\OS-Setup\Windows11\.vscode\vsc-augment",
#     ".\compile_import_into_vscode.ps1"
# )


# $MyRuntime.NewCommand(
#     "C:\Users\stasp\Documents\PowerShell",
#     [string[]]@(
#         "Invoke-Pester -Path .\Kozubenko.Utils.List.Test.ps1 -Output Detailed",
#         "Invoke-Pester -Path .\Kozubenko.Utils.List.Tests.ps1 -Output Detailed"
#     )
# )


Write-Host



# $MyRuntime.NewCommand(
#     "C:\Users\stasp\Documents\PowerShell",
#     [string[]]@(
#         "Invoke-Pester -Path .\tests\Get-Content.Test.ps1 -Output Detailed",
#         "Invoke-Pester -Path .\tests\Get-Content.Tests.ps1 -Output Detailed"
#     )
# ) 6>&1 > $null

