using module .\classes\FunctionRegistry.psm1
class KozubenkoPython {   
    static [FunctionRegistry] GetFunctionRegistry() {
        return [FunctionRegistry]::new(
            "Kozubenko.Python",
            @(
                "InitPythonEnv()                      -->   what you need after git-cloning a python project",
                "SetupBoilerplatePythonProject()      -->   setups .venv + python boilerplate project + kozubenko-py utils",
                "Activate()                           -->   .\.venv\Scripts\Activate.ps1",
                "KillPythonProcesses()                -->   kills all python processes",
                "venvFreeze()                         -->   pip freeze > requirements.txt"
            ));
    }
}


$BOILERPLATE_PYTHON_PROJECT = "$profile\..\boilerplate\python_minimum_vscode_setup"


function Activate {     # Use from a Python project root dir, to activate a venv virtual environment
    if (Test-Path "$PWD\.venv")    {
        Invoke-Expression "$PWD\.venv\Scripts\Activate.ps1";  return $true
    }
    return $false
}

function InitPythonEnv {
    py -m venv .venv
    if (Activate) {
        python.exe -m pip install --upgrade pip;

        if (Test-Path "$($PWD.Path)$([System.IO.Path]::DirectorySeparatorChar)requirements.txt") {
            py -m pip install -r requirements.txt
        }
    }
}

function SetupBoilerplatePythonProject() {
    $path = $PWD.Path

    py -m venv .venv

    .venv\Scripts\Activate.ps1

    python.exe -m pip install --upgrade pip

    Copy-Item -Path "$BOILERPLATE_PYTHON_PROJECT\*" -Destination $path -Recurse

    Clear-Host
}

function venvFreeze {
    pip freeze > requirements.txt
}

function KillPythonProcesses {
    Get-Process -Name python | Stop-Process -Force
}