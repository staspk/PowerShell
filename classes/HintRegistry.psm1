using module ..\Kozubenko.Utils.psm1


<# 
    A HintRegistry is a list of hints associated to a name.

    Hint:
        Minimum Requirement: an anchor "-->", between two [strings].
        defined as $signature, $explanation

        $hint.Print():
            expects $signature to be either  
#>
class HintRegistry {
    [string]$name
    [System.Collections.Specialized.OrderedDictionary]$hints = [ordered]@{}

    [int]$longest_signature = 0    # exposed to make consistent spacing possible, when printing multiple registrys at a time

    HintRegistry([string]$name, [Array]$hints) {
        $this.name = $name;

        foreach ($hint in $hints) {
            $signature   = ($hint.Split("-->")[0]).Trim()
            $explanation = ($hint.Split("-->")[1] ?? "").Trim()

            $this.hints.Add($signature, $explanation)

            if($signature.Length -gt $this.longest_signature) {  $this.longest_signature = $signature.Length  }
        }
    }

    <#
        $minimum_signature_char_width - refers to the length in chars of the left-hand side from "-->"
    #>
    [void] Print([int]$minimum_signature_char_width) {
        $MINIMUM_SIGNATURE_CHAR_WIDTH = $minimum_signature_char_width + 5   # 5 = (3 spaces before funcName) + (2 spaces after func_signature and '-->')
        PrintRed $this.name

        $counter = 0;
        foreach ($hint in $this.hints.GetEnumerator()) {
            $signature            =  $hint.Key
            $function_params_str  =  find_text_between_characters $signature '(' ')'
            $explanation          =  $hint.Value
            
            $is_a_function = ($function_params_str -ne $null) ? $true : $false
            $chars_printed = 0

            $_name = $signature.Split("(")[0]
            WriteLiteRed "   $_name";                         $chars_printed += 3 + $_name.Length
            if($is_a_function) {
                WriteLiteRed "(";                             $chars_printed += 1
            }
            if($function_params_str) {
                WriteItalics $function_params_str DarkGray;   $chars_printed += $function_params_str.Length
            }
            if($is_a_function) {
                WriteLiteRed ")";                             $chars_printed += 1
            }

            if($explanation) {
                $left_hand_whitespace = AddWhitespace "  " $($MINIMUM_SIGNATURE_CHAR_WIDTH - $chars_printed - 2)
                WriteLiteRed $left_hand_whitespace
                WriteLiteRed "-->"
                PrintWhiteRed "   $explanation"
            } else {
                Write-Host
            }
        }
        Write-Host
    }
}