using module ..\Kozubenko.Utils.psm1

class FunctionRegistry {
    [string]$moduleName
    [System.Collections.Specialized.OrderedDictionary]$functions = [ordered]@{}

    [int]$longest_func_signature = 0

    FunctionRegistry([string]$moduleName, [Array]$functions) {
        $this.moduleName = $moduleName;

        foreach ($function in $functions) {
            $func_signature   = $function.Split("-->")[0]
            $func_explanation = $function.Split("-->")[1] ?? ""

            $this.functions.Add($func_signature.Trim(), $func_explanation.Trim())

            if($func_signature.Length -gt $this.longest_func_signature) {  $this.longest_func_signature = $func_signature.Length  }
        }
    }

    static [void] PrintSignature([string]$function_signature, [int]$minimum_char_width) {
        $funcName = $function_signature.Split("(")[0]
        $params = $($function_signature.Split("(")[1]).Split(")")[0]

        $total_chars = 0

        PrintLiteRed "   $funcName";        $total_chars += 3 + $funcName.Length
        PrintLiteRed "(";                   $total_chars += 1
        PrintItalics $params DarkGray;      $total_chars += $params.Length
        PrintLiteRed ")";                   $total_chars += 1

        PrintLiteRed $(AddWhitespace "" $($minimum_char_width - $total_chars))
    }

    [void] Print([int]$minimum_char_width) {
        PrintRed $this.moduleName -NewLine

        $counter = 0;

        foreach ($function in $this.functions.GetEnumerator()) {
            $function_signature  = $function.Key
            $function_explanation = $function.Value

            [FunctionRegistry]::PrintSignature($function_signature, $minimum_char_width)

            if($function_explanation) {
                PrintLiteRed "  -->   "
                PrintWhiteRed "$function_explanation" -NewLine
            } else {
                Write-Host
            }
        }
        Write-Host
    }
}