using module .\classes\FunctionRegistry.psm1
using module .\Kozubenko.Utils.psm1

# Since aliases can't have params, we use functions to accomplish alias functionality...
function SetStartDirectory($path = $PWD.Path) {  $global:MyRuntime.SetStartDirectory($path)  }
function NewVar($key, $value = $PWD.Path)     {  $global:MyRuntime.NewVar($key, $value)  }
function DeleteVar($key)                      {  $global:MyRuntime.DeleteVar($key)  }
function NewCommand([string]$command)         {  $path = $PWD.Path; $global:MyRuntime.NewCommand($path, $command)  }
function Help([string]$moduleName = "")       {  $global:MyRuntime.Help($moduleName)  }


class MyRuntime {
    [string] $RUNTIME_ROOT_DIR = [System.IO.Path]::GetDirectoryName($PROFILE);

    [string] $_GLOBALS_FILE  = "$($this.RUNTIME_ROOT_DIR)\.globals";    [ordered] $globals = [ordered]@{};
    [string] $_COMMANDS_FILE = "$($this.RUNTIME_ROOT_DIR)\.commands";    [ordered] $commands = @{};

    [string] $STARTUP_DIR_KEY = "startup_dir";
    [System.Collections.Generic.List[FunctionRegistry]] $modules = [System.Collections.Generic.List[FunctionRegistry]]::new();

    MyRuntime() {  $this.Init()  }
    MyRuntime($ALT_ROOT_DIR) {
        $this._GLOBALS_FILE  = "$ALT_ROOT_DIR\.globals"
        $this._COMMANDS_FILE = "$ALT_ROOT_DIR\.commands"
        $this.Init()
    }

    hidden [void] Init() {
        $this.AddModule([FunctionRegistry]::new("Kozubenko.MyRuntime", @(
            "SetStartDirectory(`$path = `$PWD.Path)",
            "NewVar(`$key, `$value = `$PWD.Path)",
            "DeleteVar(`$key)",
            "NewCommand([string]`$command)"))
        );

        if(-not(Test-Path $this._GLOBALS_FILE))  {  Set-Content -Path $this._GLOBALS_FILE -Value "$($this.STARTUP_DIR_KEY)=$($Env:userprofile)"  }
        if(-not(Test-Path $this._COMMANDS_FILE)) {  New-Item -Path $this._COMMANDS_FILE -ItemType File -Force | Out-Null  }

        $this.globals  = [MyRuntime]::LoadEnvFileIntoMemory($this._GLOBALS_FILE, $true)
        $this.commands = [MyRuntime]::LoadEnvFileIntoMemory($this._COMMANDS_FILE)

        $this.HandleTerminalStartupLocation()
        $this.PrintIntroduction()
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

    [void] Help([string]$moduleName) {
        $minimum_signature_char_width = 34

        foreach($module in $this.modules) {
            if($module.moduleName -match $moduleName) {
                if($module.longest_func_signature -gt $minimum_signature_char_width) { $minimum_signature_char_width = $module.longest_func_signature }
            }
        }

        Clear-Host
        foreach ($module in $this.modules) {
            if($module.moduleName -match $moduleName) {
                $module.Print($minimum_signature_char_width)
            }
        }
    }
    
    SetStartDirectory($path) {
        [MyRuntime]::SaveToEnvFile($this._GLOBALS_FILE, $this.STARTUP_DIR_KEY, $path)
        $this.globals = [MyRuntime]::LoadEnvFileIntoMemory($this._GLOBALS_FILE, $true)
        $this.PrintIntroduction()
        $this.HandleTerminalStartupLocation($true);
    }

    NewVar($key, $value) {
        if([string]::IsNullOrWhiteSpace($key)) {  PrintRed "MyRuntime.NewVar(key, value): key cannot be null/whitespace. Skipping Function...`n";   RETURN;  }
        if ($key[0] -eq "$") {  $key = $key.Substring(1)  }
        [MyRuntime]::SaveToEnvFile($this._GLOBALS_FILE, $key, $value)
        $this.globals = [MyRuntime]::LoadEnvFileIntoMemory($this._GLOBALS_FILE, $true)
        $this.PrintIntroduction()
    }

    DeleteVar($key) {
        if($key[0] -eq "$") {  $key = $key.Substring(1)  }
        $this.globals = [MyRuntime]::LoadEnvFileIntoMemory($this._GLOBALS_FILE, $true, $key)
        $this.PrintIntroduction()
    }

    NewCommand($path, [object]$command) {
        if([string]::IsNullOrWhiteSpace($path) -or [string]::IsNullOrWhiteSpace($command)) {  PrintRed "MyRuntime.NewAction(path, command): command/path cannot be null/whitespace. Skipping Function...`n";   RETURN;  }
        
        PrintGreen "NewCommand(" -NewLine
        PrintGreen "   `$path: "; PrintItalics "$path`n" DarkGreen
        PrintGreen "   `$command: "; PrintItalics "$command`n" DarkGreen
        PrintGreen ")" -NewLine

        PrintLiteRed "type(`$command): "; PrintRed $(GetType $command) -NewLine

        if ($this.commands.Keys -contains $path) {
            PrintYellow "Command already exists at path."; PrintLiteRed "type(`$this.commands[`$path]: "; PrintRed $(GetType $this.commands[$path]) -NewLine
        }
        
        [MyRuntime]::SaveToEnvFile($this._COMMANDS_FILE, $path, $command)
        $this.commands = [MyRuntime]::LoadEnvFileIntoMemory($this._COMMANDS_FILE)

        Write-Host
    }

    # called from Console, by pressing Enter on empty buffer: ""
    [void] RunDefaultCommand() {
        $path = $PWD.Path

        $buffer = $null; $cursor = 0;
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$buffer, [ref]$cursor)

        $command = $this.commands[$path]
        if($command) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($command)  }
        else {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert("open " + $buffer)  }
        
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }

    [bool] CycleCommands() {
        $path = $PWD.Path

        $buffer = $null; $cursor = 0;
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$buffer, [ref]$cursor);

        $_commands = $this.commands[$path]

        if(-not($_commands)) { return $false }
        


        return $false
    }

    hidden [void] HandleTerminalStartupLocation() {  $this.HandleTerminalStartupLocation($false)  }
    hidden [void] HandleTerminalStartupLocation([bool]$force_start_dir) {
        $openedTo = $PWD.Path
        $desired_start_dir = $($this.globals[$this.STARTUP_DIR_KEY])

        if(-not($desired_start_dir)) {  RETURN;  }

        # If true, Powershell has NOT started from right_click->open_in_terminal (with specific folder in mind). 
        if ($openedTo -ieq "$env:userprofile" -or
            $openedTo -ieq "C:\WINDOWS\system32" -or
            $openedTo -ieq "C:\Users\stasp\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup" -or   # Powershell started with .ahk hotkey
            $force_start_dir
        ) {
            if(IsDirectory $desired_start_dir) {  Set-Location $desired_start_dir  }
            elseif(IsFile $desired_start_dir)  {  Set-Location $(ParentDir $desired_start_dir)  }  # QoL, so it's easy set $profile as startupLocation
            else {
                PrintRed "`$desired_start_dir path does not exist anymore. Defaulting to userdir...`n"
                Set-Location $Env:USERPROFILE
            }
        }
    }

    # static [void] SaveToEnvFile([string]$file, [System.Collections.IDictionary]$dict) {
    #     if(-not($dict -is [hashtable]) -and -not($dict -is [System.Collections.Specialized.OrderedDictionary])) {
    #         throw "SaveToEnvFile(): `$dict is neither a hashtable or dictionary"
    #     }

    #     foreach ($entry in $dict.GetEnumerator()) {
    #         "$($entry.Key) = $($entry.Value)"
    #     }
    # }

    static [void] SaveToEnvFile([string]$file, [string]$key, [string]$value) {
        # PrintYellow "In SaveToEnvFile(): `$file: "; PrintItalics "$file`n" Yellow
        $lines = [Kozubenko.Utils.List]::FromFile($file)

        if(-not($lines)) {
            [Kozubenko.Utils.List]::OverwriteFile($file, "$key=$value"); RETURN;
        }

        for ($i = 0; $i -lt $lines.Count; $i++) {
            $left = $lines[$i].Split("=")[0]
            if ($left -eq $key) {
                $lines[$i] = "$key=$value";
                [Kozubenko.Utils.List]::OverwriteFile($file, $lines); RETURN;
            }
        }
        [System.IO.File]::AppendAllText($file, "$([Environment]::NewLine)$key=$value")
    }

    static [ordered] LoadEnvFileIntoMemory([string]$file)                         {  return [MyRuntime]::LoadEnvFileIntoMemory($file, $false, $null);           }  # PrintRed "At beginning of LoadEnvFileIntoMemory(`$file):`n"
    static [ordered] LoadEnvFileIntoMemory([string]$file, [bool]$global_scope)    {  return [MyRuntime]::LoadEnvFileIntoMemory($file, $global_scope, $null);    }  # PrintRed "At beginning of LoadEnvFileIntoMemory(`$file, `$global_scope):`n"
    static [ordered] LoadEnvFileIntoMemory([string]$file, [string]$key_to_delete) {  return [MyRuntime]::LoadEnvFileIntoMemory($file, $false, $key_to_delete);  }  # PrintRed "At beginning of LoadEnvFileIntoMemory(`$file, `$key_to_delete):`n"
    static [ordered] LoadEnvFileIntoMemory([string]$file, [bool]$global_scope, [string]$key_to_delete) {
        # PrintCyan "Entering: LoadEnvFileIntoMemory(`n  `$file: $file,`n  `$global_scope: $global_scope,`n  `$key_to_delete: $key_to_delete`n): "
        $variables = [ordered]@{}
        $lines = [Kozubenko.Utils.List]::FromFile($file)
        
        if(-not($lines)) {  return $variables  }
        
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $left  = $lines[$i].Split("=")[0]
            $right = $lines[$i].Split("=")[1]

            if ([string]::IsNullOrWhiteSpace($left) -OR     # malformed key
                [string]::IsNullOrWhiteSpace($right) -OR    # malformed value
                $left -eq $key_to_delete -OR                # targeted deletion
                $variables.Keys -contains $left             # duplicate key
            ) {
                $lines.RemoveAt($i)
                if ($i -ne 0) {
                    $i--
                }
            }
            else {
                $variables[$left] = $right
                if ($global_scope) {  Set-Variable -Name $left -Value $right -Scope Global  }
            }
        }
        [Kozubenko.Utils.List]::OverwriteFile($file, $lines)
        return $variables
    }


    [void] AddModule([FunctionRegistry]$functionRegistry) {
        $this.modules.Add($functionRegistry)
    }

    [void] AddModules([Array]$functionRegistrys) {
        foreach ($funcReg in $functionRegistrys) {
            $this.AddModule($funcReg)
        }
    }
}