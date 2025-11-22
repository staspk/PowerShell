using module ..\Kozubenko.Assertions.psm1


$int = AssertInt "5"
$int = AssertInt "mary" "Correct Form: 're {int}'"

PrintGreen "Stupid Test Passed"