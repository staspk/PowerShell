using module .\classes\FunctionRegistry.psm1
using module .\Kozubenko.Utils.psm1



# Since aliases can't have params, we have to use functions to accomplish this...
function HandleConsoleState($buffer, $cursor) {  $global:MyRuntime.HandleConsoleState($buffer, $cursor) }    
function SetStartDirectory($path = $PWD.Path) {  $global:MyRuntime.SetStartDirectory($path)  }
function NewVar($name, $value = $PWD.Path)    {  $global:MyRuntime.NewVar($name, $value)  }
function DeleteVar($varName)                  {  $global:MyRuntime.DeleteVar($varName)  }


class MyRuntime {
    [string] $_GLOBALS_FILE = "$PSScriptRoot\.globals";
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

        if(-not(Test-Path $this._GLOBALS_FILE)) {
            Set-Content -Path $this._GLOBALS_FILE -Value "$($this.STARTUP_DIR_KEY)=$env:userprofile"
        }
        
        $this.LoadInGlobals($null);
        $this.HandleTerminalStartupLocation();
    }

    [void] AddModule([FunctionRegistry]$functionRegistry) {
        $this.modules.Add($functionRegistry)
    }

    [void] AddModules([Array]$functionRegistrys) {
        foreach ($functionRegistry in $functionRegistrys) {
            $this.modules.Add($functionRegistry)
        }
    }

    HandleConsoleState($buffer, $cursor) {
        PrintGreen("HandleConsoleState($buffer, $cursor)")

        # if() 
    }
    
    SetStartDirectory($path) {
        $this.SaveToGlobals($this.STARTUP_DIR_KEY, $path)
        $this.LoadInGlobals($null)
        Set-Location $global:startlocation
    }

    NewVar($name, $value) {
        AssertString $name "name"
        if ($name[0] -eq "$") {  $name = $name.Substring(1, $name.Length - 1 )  }
        $this.SaveToGlobals($name, $value)
        $this.LoadInGlobals($null)
    }

    DeleteVar($varName) {
        Clear-Host;
        if($varName[0] -eq "$") {  $varName = $varName.Substring(1)  }
        $this.LoadInGlobals($varName)
    }


    hidden [void] HandleTerminalStartupLocation() {
        $openedTo = $PWD.Path

        # If true, Powershell has NOT started from right_click->open_in_terminal (with specific folder in mind). 
        if ($openedTo -ieq "$env:userprofile" -or
            $openedTo -ieq "C:\WINDOWS\system32" -or
            $openedTo -ieq "C:\Users\stasp\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"    # Powershell started with .ahk hotkey
        ) {
            if(IsDirectory $global:startLocation) {  Set-Location $global:startLocation }
            elseif(IsFile $global:startLocation)  {  Set-Location $(ParentDir $global:startLocation)  }      # QoL, so it's easy set $profile as startupLocation
            else {
                PrintRed "`$startLocation path does not exist anymore. Defaulting to userdirectory..."
                Set-Location $Env:USERPROFILE
            }
        }
    }

    # Also does cleanup while loading into memory, e.g. duplicate removal, varToDelete.
    hidden [void] LoadInGlobals($varToDelete) {      
        $variables = @{}                                             # Dict{key==varName, value==varValue}
        $_globals  = @(Get-Content -Path $this._GLOBALS_FILE)        # "@" added, Get-Content returns string when < 2 lines, making `$lines.AddRange($_globals)` throw an exception
        
        if(-not($_globals)) {  PrintRed "Globals Empty";  RETURN;  }

        Clear-Host
        $lines = [System.Collections.Generic.List[Object]]::new(); $lines.AddRange($_globals)
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $left  = $lines[$i].Split("=")[0]
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

                if ($left -ne $this.STARTUP_DIR_KEY) {    # startLocation visible on most startups anyways, no need to be redundant
                    Write-Host "$left" -ForegroundColor White -NoNewline; Write-Host "=$right" -ForegroundColor Gray
                }
            }
        }
        Set-Content -Path $this._GLOBALS_FILE -Value $lines
        Write-Host
    }

    hidden [void] SaveToGlobals([string]$varName, $varValue) {
        $lines = (Get-Content -Path $this._GLOBALS_FILE).Split([Environment]::NewLine)
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $left = $lines[$i].Split("=")[0]
            if ($left -eq $varName) {
                $lines[$i] = "$varName=$varValue"
                Set-Content -Path $this._GLOBALS_FILE -Value $lines;   return;
            }
        }
        Add-Content -Path $this._GLOBALS_FILE -Value "$([Environment]::NewLine)$varName=$varValue"; Set-Variable -Name $varName -Value $varValue -Scope Global
    }
}