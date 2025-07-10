using module .\classes\FunctionRegistry.psm1
using module .\Kozubenko.Utils.psm1



# Since aliases can't have params, we have to use functions to accomplish this...  
function SetStartDirectory($path = $PWD.Path) {  $global:MyRuntime.SetStartDirectory($path)  }
function NewVar($name, $value = $PWD.Path)    {  $global:MyRuntime.NewVar($name, $value)    }
function DeleteVar($var_name)                 {  $global:MyRuntime.DeleteVar($var_name)    }
function NewAction([string]$command)          {  $path = $PWD.Path; $global:MyRuntime.NewAction($path, $command)  }
function See()                                {  $path = $PWD.Path; $global:MyRuntime.See($path)  }


class MyRuntime {
    [string] $_GLOBALS_FILE = "$PSScriptRoot\.globals";     $globals = [ordered]@{};
    [string] $_ACTIONS_FILE = "$PSScriptRoot\.actions";     $actions = @{};

    [string] $STARTUP_DIR_KEY = "startup_dir";
    
    [System.Collections.Generic.List[FunctionRegistry]] $modules;

    MyRuntime() {
        $this.modules = [System.Collections.Generic.List[FunctionRegistry]]::new();
        $this.AddModule([FunctionRegistry]::new(
            "Kozubenko.MyRuntime", @(
                "SetStartDirectoy(`$path = `$PWD.Path)",
                "NewVar(`$name, `$value = `$PWD.Path)",
                "DeleteVar(`$varName)"))
        );

        if(-not([Kozubenko.Utils.List]::CreateList($this._GLOBALS_FILE))) {  [System.IO.File]::WriteAllText($this._GLOBALS_FILE, "$($this.STARTUP_DIR_KEY)=$env:userprofile")  }
        if(-not(Test-Path $this._ACTIONS_FILE))                           {  [System.IO.File]::WriteAllText($this._ACTIONS_FILE, "")  }

        $this.globals = [MyRuntime]::LoadEnvFileIntoMemory($this._GLOBALS_FILE, $true);
        $this.actions = [MyRuntime]::LoadEnvFileIntoMemory($this._ACTIONS_FILE);

        $this.HandleTerminalStartupLocation();
        $this.PrintIntroduction();
    }

    [void] PrintIntroduction() {
        Clear-Host
        foreach($key in $this.globals.Keys) {
            if($key -ne $this.STARTUP_DIR_KEY) {        # no need to be redundant
                Write-Host $key -ForegroundColor White -NoNewline; Write-Host "=$($this.globals[$key])" -ForegroundColor Gray
            }
        }
        Write-Host
    }

    [void] AddModule([FunctionRegistry]$functionRegistry) {
        $this.modules.Add($functionRegistry)
    }

    [void] AddModules([Array]$functionRegistrys) {
        foreach ($functionRegistry in $functionRegistrys) {
            $this.modules.Add($functionRegistry)
        }
    }
    
    SetStartDirectory($path) {
        [MyRuntime]::SaveToEnvFile($this._GLOBALS_FILE, $this.STARTUP_DIR_KEY, $path)
        $this.globals = [MyRuntime]::LoadEnvFileIntoMemory($this._GLOBALS_FILE, $true)
        $this.PrintIntroduction()
        Set-Location $($this.globals[$this.STARTUP_DIR_KEY])
    }

    NewVar($name, $value) {
        if(-not($name)) {  PrintRed "MyRuntime.NewVar(name, value): name was falsy. Skipping.";   RETURN;  }
        if ($name[0] -eq "$") {  $name = $name.Substring(1, $name.Length - 1 )  }
        if (Test-Path $value) {  $value = (Resolve-Path $value).Path  }
        [MyRuntime]::SaveToEnvFile($this._GLOBALS_FILE, $name, $value)
        $this.globals = [MyRuntime]::LoadEnvFileIntoMemory($this._GLOBALS_FILE, $true)
        $this.PrintIntroduction()
    }

    DeleteVar($var_name) {
        if($var_name[0] -eq "$") {  $var_name = $var_name.Substring(1)  }
        $this.globals = [MyRuntime]::LoadEnvFileIntoMemory($this._GLOBALS_FILE, $true, $var_name)
        $this.PrintIntroduction()
    }

    See([string]$path) {
        PrintDarkRed "Not Implemented"
    }

    NewAction([string]$path, [string]$command) {
        if(-not($command) -or -not($path)) {  PrintRed "MyRuntime.NewAction(command, path): path or command falsy. Skipping...";   RETURN;  }
        [MyRuntime]::SaveToEnvFile($this._ACTIONS_FILE, $path, $command)
        $this.actions = [MyRuntime]::LoadEnvFileIntoMemory($this._ACTIONS_FILE)
        PrintGreen "NewAction(" $false; PrintItalics $command DarkGreen; PrintGreen ") created on: `$path: $path"
    }

    # called from Console, with: ""
    HandleDefaultAction() {
        $path = $PWD.Path

        $buffer = $null; $cursor = 0;
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$buffer, [ref]$cursor)

        $action = $this.actions[$path]
        if($action) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($action)
        } else {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert("open $action")
        }
        
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }

    hidden [void] HandleTerminalStartupLocation() {
        $openedTo = $PWD.Path

        # If true, Powershell has NOT started from right_click->open_in_terminal (with specific folder in mind). 
        if ($openedTo -ieq "$env:userprofile" -or
            $openedTo -ieq "C:\WINDOWS\system32" -or
            $openedTo -ieq "C:\Users\stasp\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"    # Powershell started with .ahk hotkey
        ) {
            $startup_dir = $this.globals[$this.STARTUP_DIR_KEY]
            if(IsDirectory $startup_dir) {  Set-Location $startup_dir }
            elseif(IsFile $startup_dir)  {  Set-Location $(ParentDir $startup_dir)  }                        # QoL, so stuff like: 'SetStartupDirectory $profile', is possible
            else {
                PrintRed "`$startup_dir path does not exist anymore. Defaulting to userdirectory..."
                Set-Location $Env:USERPROFILE
            }
        }
    }

    static [void] SaveToEnvFile([string]$file, [string]$key, [string]$value) {
        $lines = [Kozubenko.Utils.List]::CreateList($file);
        if(-not($lines)) {
            [System.IO.File]::WriteAllText($file, "$key=$value");   RETURN;
        }
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $left = $lines[$i].Split("=")[0]
            if ($left -eq $key) {
                $lines[$i] = "$key=$value";
                [Kozubenko.Utils.List]::OverwriteFile($file, $lines);    RETURN;
            }
        }
        [System.IO.File]::AppendAllText($file, "$([Environment]::NewLine)$key=$value")
    }

    static [System.Collections.Specialized.OrderedDictionary] LoadEnvFileIntoMemory([string]$file)                         {  return [MyRuntime]::LoadEnvFileIntoMemory($file, $false, $null);           }  # PrintRed "At beginning of LoadEnvFileIntoMemory(`$file):"
    static [System.Collections.Specialized.OrderedDictionary] LoadEnvFileIntoMemory([string]$file, [bool]$global_scope)    {  return [MyRuntime]::LoadEnvFileIntoMemory($file, $global_scope, $null);    }  # PrintRed "At beginning of LoadEnvFileIntoMemory(`$file, `$global_scope):"
    static [System.Collections.Specialized.OrderedDictionary] LoadEnvFileIntoMemory([string]$file, [string]$key_to_delete) {  return [MyRuntime]::LoadEnvFileIntoMemory($file, $false, $key_to_delete);  }  # PrintRed "At beginning of LoadEnvFileIntoMemory(`$file, `$key_to_delete):"
    static [System.Collections.Specialized.OrderedDictionary] LoadEnvFileIntoMemory([string]$file, [bool]$global_scope, [string]$key_to_delete) {
        # PrintRed "At beginning of LoadEnvFileIntoMemory(`$file, `$global_scope, `$key_to_delete): "
        if (-not(Test-Path $file)) {
            PrintRed "LoadEnvFileIntoMemory(" $false; PrintDarkRed "`e[3m$file`e[0m" $false; PrintRed "): Skipping Function, Not A Real Path.";
        }
        $variables = [ordered]@{}
        $lines = [Kozubenko.Utils.List]::CreateList($file)
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $left  = $lines[$i].Split("=")[0]
            $right = $lines[$i].Split("=")[1]
            if (-not($left) -or -not($right) -or $left -eq $key_to_delete -or $variables.Keys -contains $left) {
                $lines.RemoveAt($i)
                if ($i -ne 0) {
                    $i--
                }
            }
            else {
                $variables[$left] = $right
                if($global_scope) {  Set-Variable -Name $left -Value $right -Scope Global  }
            }
        }
        [Kozubenko.Utils.List]::OverwriteFile($file, $lines)
        return $variables;
    }
}