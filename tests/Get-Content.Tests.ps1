<#
-----------------------------------------------------------------------------------------------------
    Get-Content $file   [default]

    PS > $content = Get-Content $file
    Returns: 
        $null    - if empty file, ie: ""
        string   - if one line, ie: no [System.Environment]::NewLine on end of line
        Object[] - if 2< lines with truthy strings
    Note:
        $null    - if path does not exist, due to non-terminating error 
-----------------------------------------------------------------------------------------------------
#>

using module ..\Kozubenko.Utils.psm1


Describe 'Get-Content Unit Tests' {

    BeforeAll {
        $TEST_DIR = Directory $TestDrive "pester-temp" "Get-Content" "sample_files"

        [System.IO.File]::WriteAllText($(File $TEST_DIR "empty_file"), 
            ""
        )
        [System.IO.File]::WriteAllText($(File $TEST_DIR "line_with_whitespace_but_no_new_line"), 
            "    "
        )
        [System.IO.File]::WriteAllText($(File $TEST_DIR "whitespace_separated_by_one_empty_line"),
            "    " + [System.Environment]::NewLine +
            [System.Environment]::NewLine + 
            "    "
        )
        [System.IO.File]::WriteAllText($(File $TEST_DIR "one_line_with_no_new_line"), 
            "one line"
        )
        [System.IO.File]::WriteAllText($(File $TEST_DIR "two_new_lines"), 
            [System.Environment]::NewLine +
            [System.Environment]::NewLine
        )
        [System.IO.File]::WriteAllText($(File $TEST_DIR "two_str_lines_separated_by_empty_line"), 
            "line 1" + [System.Environment]::NewLine +
            [System.Environment]::NewLine +
            "line 3"
        )
    }

    AfterAll {
        Remove-Item $TEST_DIR -Recurse -Force
    }


    Context '$content = Get-Content $file' {

        It 'empty file returns $null' {
            (Get-Content $(File $TEST_DIR 'empty_file')) | Should -Be $null
        }

        It 'line with whitespace but no newline returns a single [string]' {
            (Get-Content $(File $TEST_DIR 'line_with_whitespace_but_no_new_line')) |
                Should -BeOfType ([string])
        }

        It 'one line with no newline returns a single [string]' {
            (Get-Content $(File $TEST_DIR 'one_line_with_no_new_line')) |
                Should -BeOfType ([string])
        }

        It 'two newlines returns [object[]] with 2 empty lines' {
            $result = Get-Content $(File $TEST_DIR 'two_new_lines')
            $result | Should -BeOfType ([object[]])
            $result.Count | Should -Be 2
            $result | ForEach-Object { $_ | Should -Be '' }
        }

        It 'two lines separated by an empty line returns [object[]] with 3 lines' {
            $result = Get-Content $(File $TEST_DIR 'two_str_lines_separated_by_empty_line')
            $result | Should -BeOfType ([object[]])
            $result.Count | Should -Be 3
            $result[0] | Should -Be 'line 1'
            $result[1] | Should -Be ''
            $result[2] | Should -Be 'line 3'
        }

        It 'non-existent file returns $null (non-terminating error)' {
            $result = Get-Content $(File $TEST_DIR 'nonexistent_file') -ErrorAction SilentlyContinue
            $result | Should -Be $null
        }
    }

    # ──────────────────────── 2. coerced to [string[]] ──────────────────────────
    Context 'Get-Content coerced to [string[]]' {

        It 'non-existent file coerces to empty array' {
            $res = [string[]]@(Get-Content (File $TestDir 'nonexistent_file') -ErrorAction SilentlyContinue)
            $res.Count | Should -Be 0
        }

        It 'empty file coerces to empty array' {
            ([string[]]@(Get-Content (File $TestDir 'empty_file'))).Count | Should -Be 0
        }

        It 'single line coerces to 1-element array' {
            ([string[]]@(Get-Content (File $TestDir 'one_line_with_no_new_line'))).Count | Should -Be 1
        }

        It 'multi-line coercion preserves line count (3)' {
            ([string[]]@(Get-Content (File $TestDir 'three_lines_with_linux_new_lines'))).Count | Should -Be 3
        }
    }
}