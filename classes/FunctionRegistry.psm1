using module ..\Kozubenko.Utils.psm1


function find_text_between_characters([string]$string, [char]$char1, [char]$char2) {
    <# 
    .SYNOPSIS
    Returns:
        [string] text_between_chars (includes: "")
        || $null, when: {
            - $char2 found before $char1
            - both $char1/$char2 are not found by the end of function
        }
    #>
    $char1_found = $false; $char2_found = $false;
    $_string = ""
    
    for ($i = 0; $i -lt $string.Length; $i++) {
        if(-not($char1_found) -AND $char2_found) {
            return $null;
        }

        if($string[$i] -eq $char1) {  $char1_found = $true; continue  }
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

class FunctionRegistry {
    [string]$moduleName
    [System.Collections.Specialized.OrderedDictionary]$functions = [ordered]@{}

    [int]$longest_func_signature = 0

    FunctionRegistry([string]$moduleName, [Array]$functions) {
        $this.moduleName = $moduleName;

        foreach ($function in $functions) {
            $func_signature   = ($function.Split("-->")[0]).Trim()
            $func_explanation = ($function.Split("-->")[1] ?? "").Trim()

            $this.functions.Add($func_signature, $func_explanation)

            if($func_signature.Length -gt $this.longest_func_signature) {  $this.longest_func_signature = $func_signature.Length  }
        }
    }

    <#
        $minimum_signature_char_width - refers to the length in chars of the left-hand side from "-->", ie: "function signature"
    #>
    [void] Print([int]$minimum_signature_char_width) {
        $MINIMUM_SIGNATURE_CHAR_WIDTH = $minimum_signature_char_width + 5   # 5 = (3 spaces before funcName) + (2 spaces after func_signature and '-->')
        PrintRed $this.moduleName

        $counter = 0;
        foreach ($function in $this.functions.GetEnumerator()) {
            $function_signature    =  $function.Key
            $function_params_str   =  find_text_between_characters $function_signature '(' ')'
            $function_explanation  =  $function.Value
            
            $is_a_function = ($function_params_str -ne $null) ? $true : $false
            $chars_printed = 0

            $signature = $function_signature.Split("(")[0]

            WriteLiteRed "   $signature";                        $chars_printed += 3 + $signature.Length
            if($is_a_function) {
                WriteLiteRed "(";                                $chars_printed += 1
            }
            if($function_params_str) {
                WriteItalics $function_params_str DarkGray;      $chars_printed += $function_params_str.Length
            }
            if($is_a_function) {
                WriteLiteRed ")";                                $chars_printed += 1
            }

            if($function_explanation) {
                $left_hand_whitespace = AddWhitespace "  " $($MINIMUM_SIGNATURE_CHAR_WIDTH - $chars_printed - 2)
                WriteLiteRed $left_hand_whitespace
                WriteLiteRed "-->"
                PrintWhiteRed "   $function_explanation"
            } else {
                Write-Host
            }
        }
        Write-Host
    }
}