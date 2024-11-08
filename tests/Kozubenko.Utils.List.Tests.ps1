<#
Files used in testing:
    ./sample_file/nonexistent_file    - non-existent file
    ./sample_file/empty_file          - [empty file, literally: ""]
    ./sample_file/two_new_lines       - [Lines 1-2: [Environment]::NewLine]
    ./sample_file/seven_various_lines - [Line 1,4: [Environment]::NewLine. Lines 2,3,5,7: normal lines w/ text. Line 6: made up of whitespace. TOTAL LINES: 7]
#>
using module ..\Kozubenko.Utils.psm1


Describe "[Kozubenko.Utils.List]::FromFile() Unit Tests" {
    
    Context ": `$list = [Kozubenko.Utils.List]::FromFile(`$nonexistent_file)" {
        BeforeAll {
            $nonexistent_file = File $TestDrive sample_files "nonexistent_file"
            if(Test-Path $nonexistent_file) {
                Remove-Item $nonexistent_file }

            $list = [Kozubenko.Utils.List]::FromFile($nonexistent_file)
        }

        It "Test-Path(`$nonexistent_file) should be false" {
            Test-Path $nonexistent_file | Should -BeFalse
        }
        It "`$list should be Null" {
            $list | Should -Be $null
        }
    }

    Context ": `$list = [Kozubenko.Utils.List]::FromFile(`$empty_file)" {
        BeforeAll {
            $empty_file = File $TestDrive sample_files "empty_file"
            [System.IO.File]::WriteAllText($empty_file, "")
            $list = [Kozubenko.Utils.List]::FromFile($empty_file)
        }
        It "`$list.Count == 0" {
            $list.Count | Should -Be 0
        }
        It "if(`$list) == False" {
            [bool]$list | Should -BeFalse
        }
        It "-not(`$list) == True" {
            -not($list) | Should -BeTrue
        }
    }

    Context ": `$list = [Kozubenko.Utils.List]::FromFile(`$two_new_lines)" {
        BeforeAll {
            $two_new_lines = File $TestDrive sample_files "two_new_lines"
            [System.IO.File]::WriteAllText($two_new_lines,
                [System.Environment]::NewLine +
                [System.Environment]::NewLine
            )
            $list = [Kozubenko.Utils.List]::FromFile($two_new_lines)
        }
        It "`$list.Count == 2" {
            $list.Count | Should -Be 2
        }
        It "if(`$list) == True" {
            [bool]($list) | Should -BeTrue
        }
        It "-not(`$list) == False" {
            -not($list) | Should -BeFalse
        }
    }


    Context ": `$list = [Kozubenko.Utils.List]::FromFile(`$three_lines_with_three_new_lines)" {
        BeforeAll {
            $three_lines_with_three_new_lines = File $TestDrive sample_files "three_lines_with_three_new_lines"
            [System.IO.File]::WriteAllText($three_lines_with_three_new_lines, 
                "line 1" + [System.Environment]::NewLine +
                ""       + [System.Environment]::NewLine +
                "line 3" + [System.Environment]::NewLine
            )
            $list = [Kozubenko.Utils.List]::FromFile($three_lines_with_three_new_lines)
        }

        It "`$list.Count == 3" {
            $list.Count | Should -Be 3
        }
    }

    Context ": `$list = [Kozubenko.Utils.List]::FromFile(`$seven_various_lines)" {
        BeforeAll {
            $seven_various_lines = File $TestDrive sample_files "seven_various_lines"

            [System.IO.File]::WriteAllText($seven_various_lines,
                [System.Environment]::NewLine +
                "this is line 1" + [System.Environment]::NewLine +
                "this is line 2" + [System.Environment]::NewLine +
                [System.Environment]::NewLine +
                "this is line 3" + [System.Environment]::NewLine +
                "   " + [System.Environment]::NewLine +
                "this is line 4"
            )

            $list = [Kozubenko.Utils.List]::FromFile($seven_various_lines)
        }
        It "`$list.Count == 7" {
            $list.Count | Should -Be 7
        }
        It "-not(`$list) == False" {
            -not($list) | Should -BeFalse
        }
    }
}