using module .\classes\FunctionRegistry.psm1
class KozubenkoNode {   
    static [FunctionRegistry] GetFunctionRegistry() {
        return [FunctionRegistry]::new(
            "Kozubenko.Node",
            @(
                "debug(`$file)                          -->   node --inspect-brk `$file, and opens browser debugger",
                "setupTsDevEnvironment()               -->   to run after: npx tsx 'index.ts'"
            ));
    }
}


function setupTsDevEnvironment() {
    npm install -g npm@latest
    npm install -D tsx typescript @types/node
}

# "edge://inspect/#devices"
# "chrome://inspect/#devices"
# chrome://inspect
function debug($file) {
    if(-not(Test-Path $file)) {
        PrintDarkRed "Can't find js/ts file to debug: $file"
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

