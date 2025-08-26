using module ..\Kozubenko.Utils.psm1
using module ..\Kozubenko.Runtime.psm1


Describe "[Kozubenko.Runtime] Unit Testing" {
    BeforeAll {
        class MockedRuntime : MyRuntime {
            NewCommand($path, [object]$command) {
                [MyRuntime]::NewCommand.Invoke($this, @($path, $command)) > $null
            }
        }

        function InitWithoutConfigFiles() {
            $MyRuntime = [MockedRuntime]::new($TestDrive)
            Remove-Item $MyRuntime._GLOBALS_FILE
            Remove-Item $MyRuntime._COMMANDS_FILE
            return $MyRuntime
        }
    }

    Context ": `$MyRuntime.NewCommand(str, str)" {
        BeforeAll {
            $MyRuntime = InitWithoutConfigFiles

            $MyRuntime.NewCommand(
                "C:\Users\stasp\Desktop\OS-Setup\Windows11\.vscode\vsc-augment",
                ".\compile_import_into_vscode.ps1"
            )
        }
        It "`$MyRuntime._COMMANDS_FILE should have one line" {
            $list = [Kozubenko.Utils.List]::FromFile($MyRuntime._COMMANDS_FILE)
            $list.Count | Should -Be 1
        }
    }

    # Context ": `$MyRuntime.NewCommand(str, str[])" {
    #     It "`$MyRuntime._COMMANDS_FILE should have two line" {
    #         $MyRuntime.NewCommand(
    #             "C:\Users\stasp\Desktop\OS-Setup\Windows11\.vscode\vsc-augment",
    #             ".\compile_import_into_vscode.ps1"
    #         )
    #         $list = [Kozubenko.Utils.List]::FromFile($MyRuntime._COMMANDS_FILE)
    #         $list.Count | Should -Be 1
    #     }
    # }
}

# Context ": `$list = [Kozubenko.Utils.List]::FromFile(`$nonexistent_file)" {

# }