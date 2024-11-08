<#
    
#>
using module ..\Kozubenko.Assertions.psm1
using module ..\Kozubenko.Utils.psm1


<#
-----------------------------------------------------------------------------------------------------
    PREPARING TEST FILES...
-----------------------------------------------------------------------------------------------------
#>

$SAMPLE_TEST_FILES_DIRECTORY = Directory $profile ".." tests sample_files


$nonexistent_file                 = File $SAMPLE_TEST_FILES_DIRECTORY sample_files "nonexistent_file"
$empty_file                       = File $SAMPLE_TEST_FILES_DIRECTORY sample_files "empty_file"
$str_on_one_line_but_no_new_line  = File $SAMPLE_TEST_FILES_DIRECTORY sample_files "str_on_one_line_but_no_new_line"
$two_new_lines                    = File $SAMPLE_TEST_FILES_DIRECTORY sample_files "two_new_lines"
$three_lines_with_three_new_lines = File $SAMPLE_TEST_FILES_DIRECTORY sample_files "three_lines_with_three_new_lines"
$seven_various_lines              = File $SAMPLE_TEST_FILES_DIRECTORY sample_files "seven_various_lines"

[System.IO.File]::WriteAllText($empty_file, "")
[System.IO.File]::WriteAllText($str_on_one_line_but_no_new_line,
    "one line"
)
[System.IO.File]::WriteAllText($two_new_lines,
    [System.Environment]::NewLine +
    [System.Environment]::NewLine
)
[System.IO.File]::WriteAllText($three_lines_with_three_new_lines, 
    "line 1" + [System.Environment]::NewLine +
    ""       + [System.Environment]::NewLine +
    "line 3" + [System.Environment]::NewLine
)
[System.IO.File]::WriteAllText($seven_various_lines,
    [System.Environment]::NewLine +
    "this is line 1" + [System.Environment]::NewLine +
    "this is line 2" + [System.Environment]::NewLine +
    [System.Environment]::NewLine +
    "this is line 3" + [System.Environment]::NewLine +
    "   " + [System.Environment]::NewLine +
    "this is line 4"
)


<#
-----------------------------------------------------------------------------------------------------
    THE TESTS...
-----------------------------------------------------------------------------------------------------
#>

$nonexistent_file_list                = [Kozubenko.Utils.List]::FromFile($nonexistent_file)
$empty_file_list                      = [Kozubenko.Utils.List]::FromFile($empty_file)
$str_on_one_line_but_no_new_line_list = [Kozubenko.Utils.List]::FromFile($str_on_one_line_but_no_new_line)
$two_new_lines_list                   = [Kozubenko.Utils.List]::FromFile($two_new_lines)
$seven_various_lines_list             = [Kozubenko.Utils.List]::FromFile($seven_various_lines)


AssertIsNull $nonexistent_file_list "nonexistent_file_list"
write-host
# AssertIsNull $empty_file_list "empty_file_list"
# AssertIsNotNull $empty_file_list "empty_file_list"
# AssertIsFalsy $empty_file_list "empty_file_list"
# AssertTruthyFalsySymmetry $empty_file_list "empty_file_list"
Write-Host
# AssertIsNotNull $str_on_one_line_but_no_new_line_list "str_on_one_line_but_no_new_line_list"
# AssertIsTruthy $str_on_one_line_but_no_new_line_list "str_on_one_line_but_no_new_line_list"
# AssertTruthyFalsySymmetry $str_on_one_line_but_no_new_line_list "str_on_one_line_but_no_new_line_list"


<#
-----------------------------------------------------------------------------------------------------
    CLEANUP
-----------------------------------------------------------------------------------------------------
#>
Remove-Item $SAMPLE_TEST_FILES_DIRECTORY -Recurse