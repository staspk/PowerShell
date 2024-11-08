using module .\classes\FunctionRegistry.psm1
class KozubenkoPython {   
    static [FunctionRegistry] GetFunctionRegistry() {
        return [FunctionRegistry]::new(
            "Kozubenko.Python",
            @(
                "SetupBasicPythonProject()            -->   setups .venv alongside basic necessities"
                "CreateVenvEnvironment()              -->   py -m venv .venv",
                "Activate()                           -->   .\.venv\Scripts\Activate.ps1",
                "venvFreeze()                         -->   pip freeze > requirements.txt",
                "venvInstallRequirements()            -->   py -m pip install -r requirements.txt",
                "KillPythonProcesses()                -->   kills all python processes"
            ));
    }
}


$global:venvActive = $false

$BOILERPLATE_PYTHON_PROJECT = "$profile\..\boilerplate\python_minimum_vscode_setup"

function SetupBasicPythonProject($path = $PWD.Path) {
    if (-not(Test-Path $path)) {
        PrintDarkRed "`please give valid `$path`n"
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
    if (Test-Path "$PWD\.venv")    {  Invoke-Expression "$PWD\.venv\Scripts\Activate.ps1";   $global:venvActive = $true   }
    if (Test-Path "$PWD\venv")     {  Invoke-Expression "$PWD\venv\Scripts\Activate.ps1";    $global:venvActive = $true   }
}

function venvFreeze {
    if ($global:venvActive -and (Test-Path "$PWD\.venv" -or Test-Path "$PWD\venv")) {
        pip freeze > requirements.txt
        PrintCyan "Frozen: $PWD\requirements.txt`n"
    }
    else {
        PrintRed "`$venvActive == False`n"
        PrintRed "`$venvActive == False`n"
    }
}
function venvInstallRequirements {
    if ($global:venvActive -and (Test-Path "$PWD\.venv" -or Test-Path "$PWD\venv")) {
        py -m pip install -r requirements.txt
        PrintCyan "requirements.txt installed`n"
    }
    else {
        PrintRed "`$venvActive == False`n"
    }
}

function KillPythonProcesses {
    Get-Process -Name python | Stop-Process -Force
}