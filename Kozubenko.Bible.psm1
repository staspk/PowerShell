using module .\classes\FunctionRegistry.psm1
using module .\Kozubenko.Utils.psm1
class KozubenkoBible {   
    static [FunctionRegistry] GetFunctionRegistry() {
        return [FunctionRegistry]::new(
            "Kozubenko.Bible",
            @(
                "Bible(`$passage)                       -->   `$passage == 'John:10'; opens in BibleGateway in 5 translations"
            ));
    }
}


# example use: BIBLE John:10
# example url: https://www.biblegateway.com/passage/?search=matthew23&version=kjv;nasb;rsv;rusv;nrt
function Bible($string) {
    $array = $string.Split(":")
    if($array.Count -ne 2) {  PrintRed "Bible(`$input) => input must follow format: 1John:10"; RETURN;  }
    $array[0] = Capitalize $array[0]

    $version = "kjv;nasb;rsv;rusv;nrt"
    $targetUrl = "https://www.biblegateway.com/passage/?search=$($array[0])$($array[1])&version=$version"
    $outputHtml = File "$roaming\BibleGateway\$($array[0])\$($array[1]).html"

    printred $targetUrl
    return;
    
    $webResponse = Invoke-WebRequest -Uri $targetUrl
    $htmlContent = $webResponse.Content
    Set-Content -Path $outputHtml -Value $htmlContent -Encoding UTF8

    open $(ParentDir $outputHtml)

    # Start-Process microsoft-edge:"https://www.biblegateway.com/passage/?search=$($array[0])$($array[1])&version=$version" -WindowStyle maximized
}