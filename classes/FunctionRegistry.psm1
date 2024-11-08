using module ..\Kozubenko.Utils.psm1

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
        PrintRed $this.moduleName -NewLine

        $counter = 0;
        foreach ($function in $this.functions.GetEnumerator()) {
            $function_signature   = $function.Key
            $function_explanation = $function.Value

            $chars_printed = 0

            $funcName = $function_signature.Split("(")[0]
            $params = $($function_signature.Split("(")[1]).Split(")")[0]

            PrintLiteRed "   $funcName";        $chars_printed += 3 + $funcName.Length
            PrintLiteRed "(";                   $chars_printed += 1
            PrintItalics $params DarkGray;      $chars_printed += $params.Length
            PrintLiteRed ")";                   $chars_printed += 1

            if($function_explanation) {
                $left_hand_whitespace = AddWhitespace "  " $($MINIMUM_SIGNATURE_CHAR_WIDTH - $chars_printed - 2)
                PrintLiteRed $left_hand_whitespace
                PrintLiteRed "-->"
                PrintWhiteRed "   $function_explanation" -NewLine
            } else {
                Write-Host
            }
        }
        Write-Host
    }
}