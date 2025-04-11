using module .\classes\FunctionRegistry.psm1
using module .\Kozubenko.Utils.psm1
class KozubenkoGit {   
    static [FunctionRegistry] GetFunctionRegistry() {
        return [FunctionRegistry]::new(
            "Kozubenko.Git",
            @(
                "Push(`$commitMsg = 'no_msg')           -->   push to github repo. does not work with branches",
                "UpdateSubmodules(`$merge=`$false)       -->   do not use until you update",
                "HardReset()                           -->   git reset --hard HEAD; git clean -fd"
                "GitHistory()                          -->   git log --oneline, afterwards: git show 06cb024", 
                "GitPage()                             -->   goes to remote.origin.url in the browser",
                "GitConfig(`$email, `$name)              -->   git config --global user.email `$email; etc."
            ));
    }
}


function GitConfig($email, $name) {
    git config --global user.email $email
    git config --global user.name $name
}

function Push ($commitMsg = "No Commit Message") {
    git add .
    git commit -a -m $commitMsg
    git push
}

function UpdateSubmodules($merge=$false) {
    if($merge) {  git submodule update --remote  }
    else       {  git submodule update --remote --merge  }
}

function HardReset() {
    git reset --hard HEAD
    git clean -fd
}

function GitPage($path = $PWD.Path) {
    function TryOpenGithub($path) {
        $configFile = "$path\.git\config"
        if(Test-Path $configFile) {
            $url = git config --file $configFile --get remote.origin.url
            Start-Process $url
            return $true
        } else { return $false }
    }

    if(TryOpenGithub $path) { RETURN }
    
    while(Test-Path "$path\..") {
        $path = (Resolve-Path "$path\..").Path
        if(TryOpenGithub $path) { RETURN }  
    }

    PrintRed "No .git config file found with `$path: $path, or with any ancestor";
}

function GitHistory {
    git log --oneline
}