$global:venvActive = $false

function Activate {     # Use from a Python project root dir, to activate a venv virtual environment
    if (TestPathSilently "$PWD\.venv")    {  Invoke-Expression "$PWD\.venv\Scripts\Activate.ps1";   $global:venvActive = $true   }
    if (TestPathSilently "$PWD\venv")     {  Invoke-Expression "$PWD\venv\Scripts\Activate.ps1";    $global:venvActive = $true   }
}

function venvFreeze {
    if ($global:venvActive -and (TestPathSilently "$PWD\.venv" -or TestPathSilently "$PWD\venv")) {
        pip freeze > requirements.txt
        WriteCyan "Frozen: $PWD\requirements.txt"
    }
    else {
        WriteRed "`$venvActive == False"
    }
}
function venvInstallRequirements {
    if ($global:venvActive -and (TestPathSilently "$PWD\.venv" -or TestPathSilently "$PWD\venv")) {
        py -m pip install -r requirements.txt
        WriteCyan "requirements.txt installed"
    }
    else {
        WriteRed "`$venvActive == False"
    }
}

function KillPythonProcesses {
    Get-Process -Name python | Stop-Process -Force
}