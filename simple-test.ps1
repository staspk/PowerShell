<#
Files used in testing:
    ./sample_file/test_file_0 - non-existent file
    ./sample_file/test_file_1 - [truly empty file, no new lines]
    ./sample_file/test_file_2 - [3 empty lines,    2 lines: [Environment]::NewLine]
    ./sample_file/test_file_3 - [4 lines/strings,  1 line:  [Environment]::NewLine, 1 line: made up of whitespace; TOTAL COUNT: 4]

    .\Kozubenko.Utils.Tests.ps1
#>
using module .\Kozubenko.Utils.psm1



