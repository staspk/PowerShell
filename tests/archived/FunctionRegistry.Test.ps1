using module ..\..\Kozubenko.Utils.psm1

<# 
------------------------------------------------------------------------------------------------------------------------
        FOSSIL SECTION
            note: make sure an exit(0) exists before this section
------------------------------------------------------------------------------------------------------------------------
#>

<# ---------------------------------------------------------------------------------------------------------------------
        TESTING SESSION #1 - 2025-11-5
        BUG FOUND: calling a module function like a class method was sending all params as a param1
------------------------------------------------------------------------------------------------------------------------ #>
function test_trigger() {
    $test_string = "fun()"
    [char]$char = '('
    $char_at = 3

    if($test_string[$char_at] -eq $char) {
        PrintGreen "Trigger works in this form"
    } else {
        PrintRed "Trigger does not work. Consistent"
    }
}
test_trigger

function find_text_between_characters__TEST([string]$string, [char]$char1, [char]$char2) {
    $char1_found = $false; $char2_found = $false;
    $_string = ""
    
    for ($i = 0; $i -lt $string.Length; $i++) {
        PrintDarkGray "Iteration {$i}. Current Char: $($string[$i])"
        if(-not($char1_found) -AND $char2_found) {
            return $null;
        }

        if($i -eq 6) {
            PrintGray "At the trigger point ---"
            PrintGray "   `$string[`$i]: $($string[$i])"
            PrintGray "   `$string[`$i].GetType(): $($string[$i].GetType())"
            PrintGray "   `$char1: $char1"
            PrintGray "------------------------"
            return
        }

        if($string[$i] -eq $char1) {  PrintYellow "`$char1_found on iteration {$i}" ; $char1_found = $true; continue  }
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
    PrintGreen "find_text_between_characters(`$case1) can find params in a HintRegistry" 
    PrintGreen "params: {$text}"
} elseif($null -eq $text) {
    PrintYellow "find_text_between_characters(`$case1) -> `$text is `$null" 
} else {
    PrintRed "find_text_between_characters(`$case1) cannot find params in a HintRegistry" 
}

PrintLiteRed "`$text SHOULD BE: `"$should_be`"" 

if($text -ne $should_be) {
    PrintDarkRed "`$case_1 has failed!"
}