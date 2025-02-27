using module .\classes\FunctionRegistry.psm1
class KozubenkoNode {   
    static [FunctionRegistry] GetFunctionRegistry() {
        return [FunctionRegistry]::new(
            "Kozubenko.Node",
            @(
                "fixNodeIntellisense()                 -->   npm install --save-dev @types/node; 'Go To Definition' may not work in Code without this",
                "debug(`$file)                          -->   node --inspect-brk `$file, and opens browser debugger"
            ));
    }
}


# Note: may have been a coincidence -> may have nothing to do with fixing node intellisense 
function fixNodeIntellisense() {
    npm install --save-dev @types/node
}

# "edge://inspect/#devices"
# "chrome://inspect/#devices"
# chrome://inspect
function debug($file) {
    if(-not(TestPathSilently $file)) {
        WriteDarkRed "Can't find js/ts file to debug: $file"
        RETURN;
    }
    $file = (Resolve-Path $file).Path

    $process = "Chrome"
    Start-Process $process
    $wshell = New-Object -ComObject wscript.shell;
    $wshell.AppActivate("$process")
    Start-Sleep 1
    $wshell.SendKeys("^(l)")  # Ctrl+L
    Start-Sleep 1
    $wshell.SendKeys("chrome://inspect")
    Start-Sleep 1
    $wshell.SendKeys("{ENTER}")

    node --inspect-brk $file
}

