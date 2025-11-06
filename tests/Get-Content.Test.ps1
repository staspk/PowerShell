<#
-----------------------------------------------------------------------------------------------------
    Get-Content $file   [default]

    PS > $content = Get-Content $file
    Returns:
        $null    - if path does not exist, due to non-terminating error 
        $null    - if empty file, ie: ""
        string   - if one line, but without [System.Environment]::NewLine on end of line
        Object[] - if 2< lines with truthy strings
        
-----------------------------------------------------------------------------------------------------
#>
using module ..\Kozubenko.Assertions.psm1
using module ..\Kozubenko.Utils.psm1



$SAMPLE_TEST_FILES_DIRECTORY = Directory $profile ".." tests sample_files


if(Test-Path $(File $SAMPLE_TEST_FILES_DIRECTORY "nonexistent_file")) {
    Remove-Item $(File $SAMPLE_TEST_FILES_DIRECTORY "nonexistent_file")
}

[System.IO.File]::WriteAllText($(File $SAMPLE_TEST_FILES_DIRECTORY "empty_file"), 
    ""
)

[System.IO.File]::WriteAllText($(File $SAMPLE_TEST_FILES_DIRECTORY "line_with_whitespace_but_no_new_line"), 
    "    "
)

[System.IO.File]::WriteAllText($(File $SAMPLE_TEST_FILES_DIRECTORY "whitespace_separated_by_one_empty_line"),
    "    " + [System.Environment]::NewLine +
    [System.Environment]::NewLine + 
    "    "
)

[System.IO.File]::WriteAllText($(File $SAMPLE_TEST_FILES_DIRECTORY "str_on_one_line_but_no_new_line"), 
    "one line"
)

[System.IO.File]::WriteAllText($(File $SAMPLE_TEST_FILES_DIRECTORY "two_windows_new_lines"), 
    "`r`n" +
    "`r`n"
)

[System.IO.File]::WriteAllText($(File $SAMPLE_TEST_FILES_DIRECTORY "three_lines_with_windows_new_lines"), 
    "line 1`r`n" +
    "`r`n" +
    "line 3`r`n"
)

[System.IO.File]::WriteAllText($(File $SAMPLE_TEST_FILES_DIRECTORY "three_lines_with_linux_new_lines"), 
    "line 1`n" +
    "`n" +
    "line 3`n"
)

<#
-----------------------------------------------------------------------------------------------------
    Get-Content $file   [default]

    PS > $content = Get-Content $file
-----------------------------------------------------------------------------------------------------
#>
$nonexistent_file                       = Get-Content $(File $SAMPLE_TEST_FILES_DIRECTORY "nonexistent_file")
$empty_file                             = Get-Content $(File $SAMPLE_TEST_FILES_DIRECTORY "empty_file")
$line_with_whitespace_but_no_new_line   = Get-Content $(File $SAMPLE_TEST_FILES_DIRECTORY "line_with_whitespace_but_no_new_line")
$str_on_one_line_but_no_new_line        = Get-Content $(File $SAMPLE_TEST_FILES_DIRECTORY "str_on_one_line_but_no_new_line")
$whitespace_separated_by_one_empty_line = Get-Content $(File $SAMPLE_TEST_FILES_DIRECTORY "whitespace_separated_by_one_empty_line")
$two_windows_new_lines                  = Get-Content $(File $SAMPLE_TEST_FILES_DIRECTORY "two_windows_new_lines")
$three_lines_with_windows_new_lines     = Get-Content $(File $SAMPLE_TEST_FILES_DIRECTORY "three_lines_with_windows_new_lines")
$three_lines_with_linux_new_lines       = Get-Content $(File $SAMPLE_TEST_FILES_DIRECTORY "three_lines_with_linux_new_lines")

WriteWhiteRed "`$nonexistent_file: ";                       PrintLiteRed $(GetType $nonexistent_file)
WriteWhiteRed "`$empty_file: ";                             PrintLiteRed $(GetType $empty_file)
WriteWhiteRed "`$line_with_whitespace_but_no_new_line: ";   PrintLiteRed $(GetType $line_with_whitespace_but_no_new_line)
WriteWhiteRed "`$str_on_one_line_but_no_new_line: ";        PrintLiteRed $(GetType $str_on_one_line_but_no_new_line)
WriteWhiteRed "`$whitespace_separated_by_one_empty_line: "; PrintLiteRed $(GetType $whitespace_separated_by_one_empty_line)
WriteWhiteRed "`$two_windows_new_lines: ";                  PrintLiteRed $(GetType $two_windows_new_lines)
WriteWhiteRed "`$three_lines_with_windows_new_lines: ";     PrintLiteRed $(GetType $three_lines_with_windows_new_lines)
WriteWhiteRed "`$three_lines_with_linux_new_lines: ";       PrintLiteRed $(GetType $three_lines_with_linux_new_lines)


# AssertIsNotNull $str_on_one_line_but_no_new_line "str_on_one_line_but_no_new_line_list"
# AssertIsTruthy $str_on_one_line_but_no_new_line "str_on_one_line_but_no_new_line_list"
# AssertIsFalsy $str_on_one_line_but_no_new_line "str_on_one_line_but_no_new_line_list"
AssertTruthyFalsySymmetry $str_on_one_line_but_no_new_line "str_on_one_line_but_no_new_line_list"

Write-Host "`n`n"

<#
-----------------------------------------------------------------------------------------------------
    Get-Content $file      [coercing to Array<string>]

    PS > $content = [string[]]@(Get-Content $file)
-----------------------------------------------------------------------------------------------------
#>
$nonexistent_file2                       = [string[]]@(Get-Content $(File $SAMPLE_TEST_FILES_DIRECTORY "nonexistent_file"))
$empty_file2                             = [string[]]@(Get-Content $(File $SAMPLE_TEST_FILES_DIRECTORY "empty_file"))
$line_with_whitespace_but_no_new_line2   = [string[]]@(Get-Content $(File $SAMPLE_TEST_FILES_DIRECTORY "line_with_whitespace_but_no_new_line"))
$str_on_one_line_but_no_new_line2        = [string[]]@(Get-Content $(File $SAMPLE_TEST_FILES_DIRECTORY "str_on_one_line_but_no_new_line"))
$whitespace_separated_by_one_empty_line2 = [string[]]@(Get-Content $(File $SAMPLE_TEST_FILES_DIRECTORY "whitespace_separated_by_one_empty_line"))
$two_windows_new_lines2                  = [string[]]@(Get-Content $(File $SAMPLE_TEST_FILES_DIRECTORY "two_windows_new_lines"))
$three_lines_with_windows_new_lines2     = [string[]]@(Get-Content $(File $SAMPLE_TEST_FILES_DIRECTORY "three_lines_with_windows_new_lines"))
$three_lines_with_linux_new_lines2       = [string[]]@(Get-Content $(File $SAMPLE_TEST_FILES_DIRECTORY "three_lines_with_linux_new_lines"))

WriteWhiteRed "`$nonexistent_file2: ";                       PrintLiteRed $(GetType $nonexistent_file2)
WriteWhiteRed "`$empty_file2: ";                             PrintLiteRed $(GetType $empty_file2)
WriteWhiteRed "`$line_with_whitespace_but_no_new_line2: ";   PrintLiteRed $(GetType $line_with_whitespace_but_no_new_line2)
WriteWhiteRed "`$str_on_one_line_but_no_new_line2: ";        PrintLiteRed $(GetType $str_on_one_line_but_no_new_line2)
WriteWhiteRed "`$whitespace_separated_by_one_empty_line2: "; PrintLiteRed $(GetType $whitespace_separated_by_one_empty_line2)
WriteWhiteRed "`$two_windows_new_lines2: ";                  PrintLiteRed $(GetType $two_windows_new_lines2)
WriteWhiteRed "`$three_lines_with_windows_new_lines2: ";     PrintLiteRed $(GetType $three_lines_with_windows_new_lines2)
WriteWhiteRed "`$three_lines_with_linux_new_lines2: ";       PrintLiteRed $(GetType $three_lines_with_linux_new_lines2)

Write-Host

# AssertIsFalsy $empty_file2 "empty_file2"
# AssertIsTruthy $empty_file2 "empty_file2"



<#
-----------------------------------------------------------------------------------------------------
    CLEANUP
-----------------------------------------------------------------------------------------------------
#>
Remove-Item $SAMPLE_TEST_FILES_DIRECTORY -Recurse