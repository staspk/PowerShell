using module .\classes\FunctionRegistry.psm1
using module .\Kozubenko.Utils.psm1
class KozubenkoGit {   
    static [FunctionRegistry] GetFunctionRegistry() {
        return [FunctionRegistry]::new(
            "Kozubenko.Git",
            @(
                "GitStatus()                           -->   Clear-Host; git status"
                "Push(`$commitMsg)                      -->   push to github repo. does not work with branches",
                "GitUpdateSubmodules()                 -->   git submodule update --init --recursive --remote --force",
                "GitLog(`$lines=4)                      -->   afterwards use: 'git show 06cb024'",
                "GitUncommit()                         -->   redo your last pushed commit: git reset --mixed HEAD~1",
                "GitPage()                             -->   goes to remote.origin.url in the browser",
                "SquashCommits(`$commitMsg, `$n)         -->   (n = # of all commits being combined). force push included"
            ));
    }
}

function GitStatus() {
    Clear-Host; git status
}

function Push($commitMsg = "No Commit Message") {
    git add .
    git commit -a -m $commitMsg
    git push
}

function GitUpdateSubmodules {
    git submodule update --init --recursive --remote --force
}

function GitLog($lines=4) {
    git log --oneline -$($lines)
}

function GitUncommit {
    git reset --mixed HEAD~1
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

function SquashCommits($commitMsg, $n) {
    AssertString $commitMsg "commitMsg"
    if($n -lt 2) {  PrintRed "required: n > 1"; RETURN;  }

    $need_stash = (git status --porcelain)
    if($need_stash) {
        git stash | Out-Null
        PrintGreen "Git Stash"
    }

    git reset --soft HEAD~$($n - 1)
    git commit --amend -m $commitMsg

    git push --force | Out-Null
    PrintGreen "Git Push --force"

    if($need_stash) {
        git stash pop | Out-Null
        PrintGreen "Git Stash Pop"
    }
}

function GitConfig($email, $name) {
    git config --global user.email $email
    git config --global user.name $name
}