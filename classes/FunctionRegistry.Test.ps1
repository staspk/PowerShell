using module ..\Kozubenko.Utils.psm1

<# 
    TESTS SHOW THIS LINE IS THE PAIN POINT (DOES NOT TRIGGER):
        if($string[$i] -eq $char1)
#>
function check_trigger() {
    $test_string = "fun()"
    [char]$char_needed = '('
    $char_at = 3

    if($test_string[$char_at] -eq $char_needed) {
        PrintGreen "Test Passed" -NewLine
    } else {
        PrintRed "Not supposed to reach me" -NewLine
    }
}

check_trigger;


function find_text_between_characters__TEST([string]$string, [char]$char1, [char]$char2) {
    $char1_found = $false; $char2_found = $false;
    $_string = ""
    
    for ($i = 0; $i -lt $string.Length; $i++) {
        PrintDarkGray "Iteration {$i}. Current Char: $($string[$i])" -NewLine
        if(-not($char1_found) -AND $char2_found) {
            return $null;
        }

        if($string[$i] -eq $char1) {
            PrintYellow "You need to see me"
        }

        if($string[$i] -eq $char1) {  PrintYellow "`$char1_found on iteration {$i}" -NewLine; $char1_found = $true; continue  }
        if($string[$i] -eq $char2) {
            if(-not($char1_found)) {  return $null  }
            $char2_found = $true;
            break;
        }
        
        if($char1_found) {
            $_string += $string[$i]
        }
    }

    if($char1_found -AND $char2_found) {  return $_string  }
    return $null
}



$example_case_1 = "Search(`$string, `$txt_files_only = `$false)  -->   recursively search file contents"

$text = find_text_between_characters__TEST($example_case_1, '(', ')')
$should_be = "`$string, `$txt_files_only = `$false"

# $case_1_passed = (-not([string]::IsNullOrEmpty($string))) ? $true : $false
if($text) {
    PrintGreen "find_text_between_characters(`$case1) can find params in a HintRegistry" -NewLine
    PrintGreen "params: {$text}"
} elseif($null -eq $text) {
    PrintYellow "find_text_between_characters(`$case1) -> `$text is `$null" -NewLine
} else {
    PrintRed "find_text_between_characters(`$case1) cannot find params in a HintRegistry" -NewLine
}

PrintLiteRed "`$text SHOULD BE: `"$should_be`"" -NewLine

if($text -ne $should_be) {
    PrintDarkRed "`$case_1 has failed!"
}
