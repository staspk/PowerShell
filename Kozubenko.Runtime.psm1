using module .\classes\FunctionRegistry.psm1
using module .\Kozubenko.Utils.psm1

# Since aliases can't have params, we have to use functions to accomplish this...
function SetStartDirectory($path = $PWD.Path) {  $global:MyRuntime.SetStartDirectory($path)  }
function NewVar($key, $value = $PWD.Path)     {  $global:MyRuntime.NewVar($key, $value)  }
function DeleteVar($key)                      {  $global:MyRuntime.DeleteVar($key)  }
function NewCommand([string]$command)         {  $path = $PWD.Path; $global:MyRuntime.NewCommand($path, $command)  }


class MyRuntime {
    [string] $_GLOBALS_FILE = "$PSScriptRoot\.globals";     $globals = [ordered]@{};
    [string] $_COMMANDS_FILE = "$PSScriptRoot\.actions";     $commands = @{};

    [String] $PATH_TO_GLOBALS;
    [System.Collections.Generic.List[FunctionRegistry]] $modules;

    [string] $STARTUP_DIR_KEY = "startup_dir";

    MyRuntime() {
        $this.PATH_TO_GLOBALS = $pathToGlobals;
        $this.modules = [System.Collections.Generic.List[FunctionRegistry]]::new();
        $this.AddModule([FunctionRegistry]::new("Kozubenko.MyRuntime", @(
            "SetStartDirectory(`$path = `$PWD.Path)",
            "NewVar(`$key, `$value = `$PWD.Path)",
            "DeleteVar(`$key)",
            "NewCommand([string]`$command)"))
        );

        if(-not(Test-Path $this.PATH_TO_GLOBALS)) {
            Set-Content -Path $this.PATH_TO_GLOBALS -Value "$($this.START_LOCATION_KEY)=$env:userprofile"
        }
        
        if(-not(Test-Path $this._GLOBALS_FILE)) {  Set-Content -Path $this._GLOBALS_FILE -Value "$($this.STARTUP_DIR_KEY)=$env:userprofile"  }
        if(-not(Test-Path $this._COMMANDS_FILE)) {  New-Item -Path $this._COMMANDS_FILE -ItemType File -Force | Out-Null  }

        $this.globals = [MyRuntime]::LoadEnvFileIntoMemory($this._GLOBALS_FILE, $true, "");
        # $this.commands = [MyRuntime]::LoadEnvFileIntoMemory($this._COMMANDS_FILE, "");



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
        foreach ($funcReg in $functionRegistrys) {
            $this.AddModule($funcReg)
        }
    }
    
    SetStartDirectory($path) {
        [MyRuntime]::SaveToEnvFile($this._GLOBALS_FILE, $this.STARTUP_DIR_KEY, $path)
        $this.globals = [MyRuntime]::LoadEnvFileIntoMemory($this._GLOBALS_FILE, $true, "")
        $this.PrintIntroduction()
        Set-Location $($this.globals[$this.STARTUP_DIR_KEY])
    }

    NewVar($key, $value) {
        if([string]::IsNullOrWhiteSpace($key)) {  PrintRed "MyRuntime.NewVar(name, value): name is null or is whitespace. Skipping.";   RETURN;  }
        if ($key[0] -eq "$") {  $key = $key.Substring(1)  }
        [MyRuntime]::SaveToEnvFile($this._GLOBALS_FILE, $key, $value)
        $this.globals = [MyRuntime]::LoadEnvFileIntoMemory($this._GLOBALS_FILE, $true, "")
        $this.PrintIntroduction()
    }

    DeleteVar($key) {
        if($key[0] -eq "$") {  $key = $key.Substring(1)  }
        $this.globals = [MyRuntime]::LoadEnvFileIntoMemory($this._GLOBALS_FILE, $true, $key)
        $this.PrintIntroduction()
    }

    NewCommand($path, [string]$command) {
        if(-not($command) -or -not($path)) {  PrintRed "MyRuntime.NewAction(command, path): command/path was falsy. Skipping.";   RETURN;  }
        [MyRuntime]::SaveToEnvFile($this._COMMANDS_FILE, $path, $command)
        $this.commands = [MyRuntime]::LoadEnvFileIntoMemory($this._GLOBALS_FILE)
        PrintGreen "NewAction(" $false; PrintItalics $command DarkGreen; PrintGreen ") created on: `$path: $path"
    }

    # called from Console, with: ""
    HandleDefaultAction() {
        $path = $PWD.Path

        $buffer = $null; $cursor = 0;
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$buffer, [ref]$cursor)

        $command = $this.commands[$path]
        if(-not($command)) {
            PrintRed "No Default Action Assigned at `$PWD";  RETURN;  }

        [Microsoft.PowerShell.PSConsoleReadLine]::Insert($command)
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }


    hidden [void] HandleTerminalStartupLocation() {
        $openedTo = $PWD.Path

        # If true, Powershell has NOT started from right_click->open_in_terminal (with specific folder in mind). 
        if ($openedTo -ieq "$env:userprofile" -or
            $openedTo -ieq "C:\WINDOWS\system32" -or
            $openedTo -ieq "C:\Users\stasp\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"    # Powershell started with .ahk hotkey
        ) {
            if(IsDirectory $global:startLocation) {  Set-Location $($this.globals[$this.STARTUP_DIR_KEY]) }
            elseif(IsFile $global:startLocation)  {  Set-Location $(ParentDir $($this.globals[$this.STARTUP_DIR_KEY]))  }  # QoL, so it's easy set $profile as startupLocation
            else {
                PrintRed "`$$($this.STARTUP_DIR_KEY) path does not exist anymore. Defaulting to userdirectory..."
                Set-Location $Env:USERPROFILE
            }
        }
    }

    static [void] SaveToEnvFile([string]$file, [string]$key, [string]$value) {
        $lines = [Kozubenko.Utils.List]::CreateList($file);
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $left = $lines[$i].Split("=")[0]
            if ($left -eq $key) {
                $lines[$i] = "$key=$value";
                [System.IO.File]::WriteAllText($file, $lines);   RETURN;
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

    static [System.Collections.Specialized.OrderedDictionary] LoadEnvFileIntoMemory([string]$file, [bool]$global_scope, [string]$key_to_delete) {
        PrintRed "At beginning of LoadEnvFileIntoMemory($file, $global_scope, $key_to_delete): "
        if (-not(Test-Path $file)) {
            PrintRed "LoadEnvFileIntoMemory(" $false; PrintDarkRed "`e[3m$file`e[0m" $false; PrintRed "): Skipping Function, Not A Real Path."; return;
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
                if ($global_scope) {
                    Set-Variable -Name $left -Value $right -Scope Global
                }
            }
            [Kozubenko.Utils.List]::OverwriteFile($file, $lines)
            return $variables
        }
    }



    hidden [void] LoadInGlobals($varToDelete) {      # Cleanup while loading-in, e.g. duplicate removal, varToDelete.
        $variables = @{}   # Dict{key==varName, value==varValue}
        $_globals = @(Get-Content -Path $this.PATH_TO_GLOBALS)      # "@" added, Get-Content returns string when < 2 lines, making `$lines.AddRange($_globals)` throw an exception
        
        if(-not($_globals)) {  PrintRed "Globals Empty";  RETURN;  }

        Clear-Host
        $lines = [System.Collections.Generic.List[Object]]::new(); $lines.AddRange($_globals)
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $left = $lines[$i].Split("=")[0]
            $right = $lines[$i].Split("=")[1]
            if ($left -eq "" -or $right -eq "" -or $left -eq $varToDelete -or $variables.ContainsKey($left)) {    # is duplicate if $variables.containsKey($left)
                $lines.RemoveAt($i)
                if ($i -ne 0) {
                    $i--
                }
            }
            else {
                
                $variables.Add($left, $right)
                Set-Variable -Name $left -Value $right -Scope Global

                if ($left -ne $this.START_LOCATION_KEY) {    # startLocation visible on most startups anyways, no need to be redundant
                    Write-Host "$left" -ForegroundColor White -NoNewline; Write-Host "=$right" -ForegroundColor Gray
                }
            }
        }
        Set-Content -Path $this.PATH_TO_GLOBALS -Value $lines
        Write-Host
    }

    hidden [void] SaveToGlobals([string]$varName, $varValue) {
        $lines = (Get-Content -Path $this.PATH_TO_GLOBALS).Split([Environment]::NewLine)
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $left = $lines[$i].Split("=")[0]
            if ($left -eq $varName) {
                $lines[$i] = "$varName=$varValue"
                Set-Content -Path $this.PATH_TO_GLOBALS -Value $lines;   return;
            }
        }
        Add-Content -Path $this.PATH_TO_GLOBALS -Value "$([Environment]::NewLine)$varName=$varValue"; Set-Variable -Name $varName -Value $varValue -Scope Global
    }
}