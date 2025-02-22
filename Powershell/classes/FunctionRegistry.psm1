class FunctionRegistry {
    [string]$moduleName
    [Array]$functions = @()

    FunctionRegistry([string]$moduleName, [Array]$functions) {
        $this.moduleName = $moduleName;
        $this.functions = $($this.functions; $functions)
    }

    [void] AddMethods([Array]$newMethods) {

    }
}