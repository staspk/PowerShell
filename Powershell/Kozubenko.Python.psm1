$global:venvActive = $false

function Activate {     # Use from a Python project root dir, to activate a venv virtual environment
    if (TestPathSilently "$PWD\.venv")    {  Invoke-Expression "$PWD\.venv\Scripts\Activate.ps1";   $global:venvActive = $true   }
    if (TestPathSilently "$PWD\venv")     {  Invoke-Expression "$PWD\venv\Scripts\Activate.ps1";    $global:venvActive = $true   }
}

function Freeze {
    if ($venvActive -and (TestPathSilently "$PWD\.venv" -or TestPathSilently "$PWD\venv")) {
        pip freeze > requirements.txt
        WriteCyan "Frozen: $PWD\requirements.txt"
    }
}