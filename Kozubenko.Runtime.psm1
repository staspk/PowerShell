using module .\classes\FunctionRegistry.psm1
using module .\Kozubenko.Utils.psm1

# Since aliases can't have params, we have to use functions to accomplish this...
function SetStartLocation($path = $PWD.Path)  {  $global:MyRuntime.SetStartLocation($path)  }
function NewVar($name, $value = $PWD.Path)    {  $global:MyRuntime.NewVar($name, $value)  }
function SetVar($name, $value)                {  $global:MyRuntime.SetVar($name, $value)  }
function DeleteVar($varName)                  {  $global:MyRuntime.DeleteVar($varName)  }

class MyRuntime {
    [String] $PATH_TO_GLOBALS;
    [System.Collections.Generic.List[FunctionRegistry]] $modules;

    [string] $START_LOCATION_KEY = "startLocation";

    MyRuntime([string]$pathToGlobals) {
        $this.PATH_TO_GLOBALS = $pathToGlobals;
        $this.modules = [System.Collections.Generic.List[FunctionRegistry]]::new();
        $this.AddModule([FunctionRegistry]::new("Kozubenko.MyRuntime", @(
            "SetStartLocation(`$path = `$PWD.Path)",
            "NewVar(`$name, `$value = `$PWD.Path)",
            "SetVar(`$name, `$value)",
            "DeleteVar(`$varName)"))
        );

        if(-not(TestPathSilently($this.PATH_TO_GLOBALS))) {
            Set-Content -Path $this.PATH_TO_GLOBALS -Value "$($this.START_LOCATION_KEY)=$env:userprofile"
        }
        
        $this.LoadInGlobals($null);
        $this.HandleStartupConsoleLocation();
    }

    [void] AddModule([FunctionRegistry]$functionRegistry) {
        $this.modules.Add($functionRegistry)
    }

    [void] AddModules([Array]$functionRegistrys) {
        foreach ($funcReg in $functionRegistrys) {
            $this.AddModule($funcReg)
        }
    }
    
    SetStartLocation($path) {   # PUBLIC
        $this.SaveToGlobals($this.START_LOCATION_KEY, $path)
        $this.LoadInGlobals($null)
        Set-Location $global:startlocation
    }

    NewVar($name, $value) {   # PUBLIC
        if ([string]::IsNullOrEmpty($name)) {  RETURN  }
        if ($name[0] -eq "$") {  $name = $name.Substring(1, $name.Length - 1 )  }
        $this.SaveToGlobals($name, $value)
        $this.LoadInGlobals($null)
    }

    SetVar($name, $value) {   # PUBLIC
        if ([string]::IsNullOrEmpty($name) -or [string]::IsNullOrEmpty($value)) {  RETURN  }
        if ($name[0] -eq "$") {  $name = $name.Substring(1, $name.Length - 1 )  }
        $this.SaveToGlobals($name, $value)
        $this.LoadInGlobals($null)
    }

    DeleteVar($varName) {    # PUBLIC
        Clear-Host; $this.LoadInGlobals($varName)
    }


    hidden [void] HandleStartupConsoleLocation() {
        $openedTo = $PWD.Path
        if ($openedTo -ieq "$env:userprofile" -or $openedTo -ieq "C:\WINDOWS\system32") {   # If true, Powershell almost certainly started from taskbar/shortcut, not from right_click->open_in_terminal with specific dir in mind => checking if globals file has $global:startLocation...
            if ($global:startLocation -eq $null) {
                # Do Nothing
            }
            elseif(IsDirectory $global:startLocation) {  Set-Location $global:startLocation }
            elseif(IsFile $global:startLocation)      {  Set-Location $([System.IO.Path]::GetDirectoryName($global:startLocation))  }  # QoL, so it's easy to add eg: $startupLocation==$profile ie: the containing directory of a file, without being specific
            else {
                PrintRed "`$startLocation path does not exist anymore. Defaulting to userdirectory..."
                Set-Location $Env:USERPROFILE
            }
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