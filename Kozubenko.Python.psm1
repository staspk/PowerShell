using module .\classes\FunctionRegistry.psm1
class KozubenkoPython {   
    static [FunctionRegistry] GetFunctionRegistry() {
        return [FunctionRegistry]::new(
            "Kozubenko.Python",
            @(
                "SetupBasicPythonProject()             -->   setups .venv alongside basic necessities"
                "CreateVenvEnvironment()               -->   py -m venv .venv",
                "Activate()                            -->   .\.venv\Scripts\Activate.ps1",
                "venvFreeze()                          -->   pip freeze > requirements.txt",
                "venvInstallRequirements()             -->   py -m pip install -r requirements.txt",
                "KillPythonProcesses()                 -->   kills all python processes"
            ));
    }
}


$global:venvActive = $false

$BOILERPLATE_PYTHON_PROJECT = "$profile\..\boilerplate\python_minimum_vscode_setup"

function SetupBasicPythonProject($path = $PWD.Path) {
    if (-not(TestPathSilently $path)) {
        WriteDarkRed "`please give valid `$path"
        RETURN;
    }

    py -m venv .venv

    .venv\Scripts\Activate.ps1

    python.exe -m pip install --upgrade pip

    Copy-Item -Path "$BOILERPLATE_PYTHON_PROJECT\*" -Destination $path -Recurse

    Clear-Host
}


function CreateVenvEnvironment {
    py -m venv .venv
    Activate
    python.exe -m pip install --upgrade pip;
}

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