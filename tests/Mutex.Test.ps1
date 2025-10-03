<#
    TO START TEST:
    $script_file = [System.IO.Path]::Combine($profile, '..', 'tests', 'Mutex.Test.ps1')
    for ($i = 0; $i -lt 3; $i++) {
        Start-Process pwsh -ArgumentList "-NoExit -File $script_file"
    }
#>
using module ..\Kozubenko.Utils.psm1



$SAMPLE_TEST_FILES_DIRECTORY = Directory $profile ".." tests sample_files
function Cleanup {
    try {
        Remove-Item $SAMPLE_TEST_FILES_DIRECTORY -Recurse -Force
    }
    catch {
        PrintYellow "I am not the Process responsible for Cleanup"
    }
}


$STRING = "The standard Lorem Ipsum passage, used since the 1500s
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,

Section 1.10.32 of de Finibus Bonorum et Malorum, written by Cicero in 45 BC
Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore
"

# $sw = [System.Diagnostics.Stopwatch]::StartNew()


$TXT_FILE_1 = File $SAMPLE_TEST_FILES_DIRECTORY "file_001.txt"
$TXT_FILE_2 = File $SAMPLE_TEST_FILES_DIRECTORY "file_002.txt"

$mutex = [System.Threading.Mutex]::new($false, "PowerShell.Mutex.Test")     <# maybe try GLOBAL\ #>

$mutex.WaitOne() | Out-Null

$fileStream = [System.IO.File]::Open(
    $TXT_FILE_1,
    [System.IO.FileMode]::OpenOrCreate,
    [System.IO.FileAccess]::ReadWrite,
    [System.IO.FileShare]::None
)

[System.Threading.Thread]::Sleep(2000);

$fileStream.Close()

$mutex.ReleaseMutex()


PrintGreen "Test Passed (if no exception above in all terminals)" -NewLine

<# CLEANUP #>
try {
    Remove-Item $SAMPLE_TEST_FILES_DIRECTORY -Recurse -Force -ErrorAction Stop  <#  Remove-Item is a non-terminating error, so try-catch will not work without "-ErrorAction Stop"  #>
    PrintYellow "I was the Process responsible for Cleanup" -NewLine
}
catch {
    
}