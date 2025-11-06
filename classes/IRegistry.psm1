using module .\HintRegistry.psm1

class IRegistry
{
    static [HintRegistry] GetRegistry()
    {
        throw("classes implementing IRegistry MUST implement method: GetRegistry().")
    }
}