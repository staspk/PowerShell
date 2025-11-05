using module .\Kozubenko.Utils.psm1
using module .\classes\FunctionRegistry.psm1
class KozubenkoPython {   
    static [FunctionRegistry] GetFunctionRegistry() {
        return [FunctionRegistry]::new(
            "Kozubenko.Python",
            @(
                "InitPythonEnv()           -->   what you need after git-cloning a python project",
                "PythonBoilerplate()       -->   python QoL boilerplate + kozubenko-py utils",
                "Activate()                -->   .\.venv\Scripts\Activate.ps1",
                "KillPythonProcesses()     -->   kills all python processes",
                "venvFreeze()              -->   pip freeze > requirements.txt",
                "upgrade project .venv     -->   py -3.14 -m venv .venv"
            ));
    }
}


$BOILERPLATE_PYTHON_PROJECT = "$profile\..\boilerplate\python_vscode_setup"
if(-not(Test-Path $BOILERPLATE_PYTHON_PROJECT)) {  PrintRed "`$BOILERPLATE_PYTHON_PROJECT Directory Not Found!";  Start-Sleep 1;  }


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

function PythonBoilerplate() {
    Copy-Item -Path "$BOILERPLATE_PYTHON_PROJECT\*" -Destination $PWD -Recurse
}

function venvFreeze {
    pip freeze > requirements.txt
}

function KillPythonProcesses {
    Get-Process -Name python | Stop-Process -Force
}