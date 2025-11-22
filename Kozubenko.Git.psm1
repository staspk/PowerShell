using module .\classes\IRegistry.psm1
using module .\classes\HintRegistry.psm1
using module .\Kozubenko.Utils.psm1
class KozubenkoGit : IRegistry {   
    static [HintRegistry] GetRegistry() {
        return [HintRegistry]::new(
            "Kozubenko.Git",
            @(
                "SquashCommits(`$commitMsg, `$n)      -->   (n = # of all commits being combined). force push included",
                "ClearStashGit()                      -->   git stash clear",
                "GitPage()                            -->   goes to remote.origin.url in the browser",
                "GitStatus()                          -->   Clear-Host; git status"
                "GitLog(`$lines=4)                    -->   afterwards use: 'git show 06cb024'",

                "I am rebasing!                          -->   [dd -> cut line] [P -> paste] [fixup -> merges into above commit]",

                "I want to update Submodules                -->  git submodule update --remote [--recursive]",
                "I want to uncommit my last push            -->  git reset --mixed HEAD~1"
                "I want to push new local branch to Github  -->  git push -u origin <branch-name>"
            ));
    }
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

    if(TryOpenGithub $path) {  RETURN;  }
    while($true) {
        $path = [System.IO.Path]::GetDirectoryName($path)
        if(-not($path)) {  PrintRed ".git config file not found. not at `$path, not with any ancestor"; RETURN;  }
        if(TryOpenGithub $path) {  RETURN;  }
    }
}

function ClearStashGit() {
    git stash clear
}

function GitStatus() {
    Clear-Host; git status
}

function SquashCommits($commitMsg, $n) {
    if([string]::IsNullOrWhiteSpace($commitMsg)) {  PrintRed "SquashCommits(): cannot continue because`$commitMsg is null/whitespace."; RETURN;  }
    if($n -lt 2) {  PrintRed "SquashCommits(`$commitMsg, `$n): Requirement not met: `$n > 1"; RETURN;  }

    $need_stash = (git status --porcelain)
    if($need_stash) {
        git stash clear
        git stash
    }

    git reset --soft HEAD~$($n - 1)
    git commit --amend -m $commitMsg

    git push --force-with-lease
    PrintGreen "Squashed & Force-Pushed to Remote"

    if($need_stash) {
        git stash pop
    }
}

function GitConfig($email, $name) {
    git config --global user.email $email
    git config --global user.name $name
}

function GitLog($lines=4) {
    git log --oneline -$($lines)
}


<# 
    :: The Fossil Record ::
#>

# "Push(`$commitMsg)                    -->   push to github repo. does not work with branches"
# function Push($commitMsg = "No Commit Message") {
#     git add .
#     git commit -a -m $commitMsg
#     git push
# }