using module .\classes\IRegistry.psm1
using module .\classes\HintRegistry.psm1
using module .\Kozubenko.Utils.psm1
class KozubenkoVideo {
    static [HintRegistry] GetRegistry() {
        return [HintRegistry]::new(
            "Kozubenko.Video",
            @(
                "vtt_to_srt(`$file)                 -->   convert subtitles from format .vtt to .srt",
                "webm_to_mp4(`$file)                -->   convert webm to mp4 file, crt==18 (visually lossless)"
            ))
    }
}

function vtt_to_srt($file) {
    if (-not(Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
        PrintRed "ffmpeg library required for function."
        RETURN;
    }

    $new_file = ""
    if($file.Substring($file.Length - 4) -eq ".vtt") {  $new_file = "$($file.Substring(0, $file.Length - 4)).srt"  }
    else {$new_file = "$file.srt"}

    PrintGreen "output: $new_file"

    ffmpeg -i "$file" -c:s subrip "$new_file" -loglevel quiet
}
function webm_to_mp4($file) {
    if (-not(Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
        PrintRed "ffmpeg library required for function."
        RETURN;
    }

    $new_file = ""
    if($file.Substring($file.Length - 5) -eq ".webm") {  $new_file = "$($file.Substring(0, $file.Length - 5)).mp4"  }
    else {$new_file = "$file.mp4"}

    ffmpeg -i "$file" -c:v libx264 -crf 18 -preset medium "$new_file"
}