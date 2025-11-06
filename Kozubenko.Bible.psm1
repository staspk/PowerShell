using module .\classes\IRegistry.psm1
using module .\classes\HintRegistry.psm1
using module .\Kozubenko.Utils.psm1
class KozubenkoBible : IRegistry {
    static [HintRegistry] GetRegistry() {
        return [HintRegistry]::new(
            "Kozubenko.Bible",
            @(
                "{BibleBook}(`$chapter)             -->   e.g: '1John 1'; opens BibleGateway in 5 translations"
            ));
    }
}

$BIBLE = @{
    "Genesis"        = 50
    "Exodus"         = 40
    "Leviticus"      = 27
    "Numbers"        = 36
    "Deuteronomy"    = 34
    "Joshua"         = 24
    "Judges"         = 21
    "Ruth"           = 4
    "1Samuel"        = 31
    "2Samuel"        = 24
    "1Kings"         = 22
    "2Kings"         = 25
    "1Chronicles"    = 29
    "2Chronicles"    = 36
    "Ezra"           = 10
    "Nehemiah"       = 13
    "Esther"         = 10
    "Job"            = 42
    "Psalms"         = 150
    "Proverbs"       = 31
    "Ecclesiastes"   = 12
    "SongOfSolomon"  = 8
    "Isaiah"         = 66
    "Jeremiah"       = 52
    "Lamentations"   = 5
    "Ezekiel"        = 48
    "Daniel"         = 12
    "Hosea"          = 14
    "Joel"           = 3
    "Amos"           = 9
    "Obadiah"        = 1
    "Jonah"          = 4
    "Micah"          = 7
    "Nahum"          = 3
    "Habakkuk"       = 3
    "Zephaniah"      = 3
    "Haggai"         = 2
    "Zechariah"      = 14
    "Malachi"        = 4
    "Matthew"        = 28
    "Mark"           = 16
    "Luke"           = 24
    "John"           = 21
    "Acts"           = 28
    "Romans"         = 16
    "1Corinthians"   = 16
    "2Corinthians"   = 13
    "Galatians"      = 6
    "Ephesians"      = 6
    "Philippians"    = 4
    "Colossians"     = 4
    "1Thessalonians" = 5
    "2Thessalonians" = 3
    "1Timothy"       = 6
    "2Timothy"       = 4
    "Titus"          = 3
    "Philemon"       = 1
    "Hebrews"        = 13
    "James"          = 5
    "1Peter"         = 5
    "2Peter"         = 3
    "1John"          = 5
    "2John"          = 1
    "3John"          = 1
    "Jude"           = 1
    "Revelation"     = 22
}
function Bible($book, $chapter) {
    if($book -notin $BIBLE.Keys) {  PrintRed "Book does not exist: $book`n"; RETURN;  }
    if($chapter -lt 1 -OR $chapter -gt $BIBLE[$book]) {  PrintRed "Chapter does not exist: $($book):$($chapter)`n"; RETURN;  }

    $translations = "kjv;nasb;rsv;rusv;nrt"
    $translations2 = "nkjv;esv;nrsv;niv;net"

    if($book[0] -eq "1" -OR $book[0] -eq "2" -OR $book[0] -eq "3") {        # adding space to from "1Samuel" & "3John"
        $book = "$($book[0]) $($book.Substring(1))"
    }

    $targetUrl = "https://www.biblegateway.com/passage/?search=$book%20$chapter&version=$translations"      # %20 == space, e.g: ' '
    $targetUrl2 = "https://www.biblegateway.com/passage/?search=$book%20$chapter&version=$translations2"

    Start-Process microsoft-edge:"$targetUrl" -WindowStyle maximized
    Start-Process microsoft-edge:"$targetUrl2" -WindowStyle maximized
}

<#
    uses above $BIBLE dict to construct dynamic functions that all internally call Bible(). e.g: 1John(5) calls Bible(1John, 5)
#>
foreach ($book in $BIBLE.Keys) {
    $scriptBlock = {
        param(
            [Parameter(ValueFromRemainingArguments=$true)]
            $PassthroughArgs
        )
        Bible $book @PassthroughArgs                                                  # @ == splatting operator. passes each value in array as separate arg
    }.GetNewClosure()

    New-Item -Path "Function:\$book" -Value $scriptBlock -Force -ErrorAction Stop

    if($book -eq "Psalms") {
        New-Item -Path "Function:\Psalm" -Value $scriptBlock -Force -ErrorAction Stop
    }
}