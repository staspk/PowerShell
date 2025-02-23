using module .\classes\FunctionRegistry.psm1
class KozubenkoNode {   
    static [FunctionRegistry] GetFunctionRegistry() {
        return [FunctionRegistry]::new(
            "Kozubenko.Node",
            @(
                "fixNodeIntellisense()             -->  npm install --save-dev @types/node; 'Go To Definition' will not work in Code without this",
                "debug(`$file)                      -->  node --inspect-brk `$file, and opens browser debugger"
            ));
    }
}

function fixNodeIntellisense() {
    npm install --save-dev @types/node
}

# "edge://inspect/#devices"
# "chrome://inspect/#devices"
function debug($file) {
    if(-not(TestPathSilently $file)) {
        WriteDarkRed "Can't find js/ts file to debug: $file"
        Return;
    }
    $file = (Resolve-Path $file).Path
    Start-Process "chrome.exe"

    node --inspect-brk $file
}

