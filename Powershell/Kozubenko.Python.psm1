using module .\classes\FunctionRegistry.psm1
class KozubenkoPython {   
    static [FunctionRegistry] GetFunctionRegistry() {
        return [FunctionRegistry]::new(
            "Kozubenko.Python",
            @(
                "CreateVenvEnvironment()               -->   py -m venv .venv",
                "Activate()                            -->   activate venv/.venv environment",
                "venvFreeze()                          -->   pip freeze > requirements.txt; pip freeze -> print to console",
                "venvInstallRequirements()             -->   py -m pip install -r requirements.txt",
                "KillPythonProcesses()                 -->   kills all python processes"
            ));
    }
}


$global:venvActive = $false

function CreateVenvEnvironment {
    py -m venv .venv
    python.exe -m pip install --upgrade pip;
    Activate
}

function Activate {     # Use from a Python project root dir, to activate a venv virtual environment
    if (TestPathSilently "$PWD\.venv")    {  Invoke-Expression "$PWD\.venv\Scripts\Activate.ps1";   $global:venvActive = $true   }
    if (TestPathSilently "$PWD\venv")     {  Invoke-Expression "$PWD\venv\Scripts\Activate.ps1";    $global:venvActive = $true   }
}

function venvFreeze($onlyPrint) {
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
