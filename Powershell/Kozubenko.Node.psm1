using module .\classes\FunctionRegistry.psm1
class KozubenkoNode {   
    static [FunctionRegistry] GetFunctionRegistry() {
        return [FunctionRegistry]::new(
            "Kozubenko.Node",
            @(
                "fixNodeIntellisense()             -->  npm install --save-dev @types/node; 'Go To Definition' will not work in Code without this"
            ));
    }
}

function fixNodeIntellisense() {
    npm install --save-dev @types/node
}