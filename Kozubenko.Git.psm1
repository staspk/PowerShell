using module .\classes\FunctionRegistry.psm1
using module .\Kozubenko.Utils.psm1
class KozubenkoGit {   
    static [FunctionRegistry] GetFunctionRegistry() {
        return [FunctionRegistry]::new(
            "Kozubenko.Git",
            @(
                "GitPage()                            -->   goes to remote.origin.url in the browser",
                "GitStatus()                          -->   Clear-Host; git status"
                "Push(`$commitMsg)                    -->   push to github repo. does not work with branches",
                "GitLog(`$lines=4)                    -->   afterwards use: 'git show 06cb024'",
                "GitUncommit()                        -->   redo your last pushed commit: git reset --mixed HEAD~1",
                "SquashCommits(`$commitMsg, `$n)      -->   (n = # of all commits being combined). force push included",
                "Rebase(`$commitsBack)                -->   [dd -> cut line] [P -> paste] [squash -> merges into above commit]",
                "RecursiveSubmoduleUpdate(`$force)    -->   git submodule update --init --recursive --remote [--force]",

                "I want to push new local branch to Github     -->   git push -u origin <branch-name>"
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

    if(TryOpenGithub $path) {  RETURN;  }
    while($true) {
        $path = [System.IO.Path]::GetDirectoryName($path)
        if(-not($path)) {  PrintRed ".git config file not found. not at `$path, not with any ancestor`n"; RETURN;  }
        if(TryOpenGithub $path) {  RETURN;  }
    }
}

<#
PLEASE LOOK INTO REPLACING "git push --force" with "git push --force-with-lease":
This may work, needs testing:
    $output = git push --force-with-lease 2>&1
    $exitCode = $LASTEXITCODE
#>
function SquashCommits($commitMsg, $n) {
    if([string]::IsNullOrWhiteSpace($commitMsg)) {  PrintRed "SquashCommits(): cannot continue because`$commitMsg is null/whitespace."; RETURN;  }
    if($n -lt 2) {  PrintRed "SquashCommits(`$commitMsg, `$n): Requirement not met: `$n > 1`n"; RETURN;  }

    $need_stash = (git status --porcelain)
    if($need_stash) {
        git stash
    }

    git reset --soft HEAD~$($n - 1)
    git commit --amend -m $commitMsg

    git push --force
    PrintGreen "Squashed & Force-Pushed to Remote`n"

    if($need_stash) {
        git stash pop
    }
}

function Rebase([int]$commitsBack) {
    $global:rebaseStarted = $true

    $stash_necessary = (git status --porcelain)
    if($stash_necessary) {
        git stash
        PrintYellow "git stash-ed"
    }
    git rebase -i HEAD~$($commitsBack)
}

function GitConfig($email, $name) {
    git config --global user.email $email
    git config --global user.name $name
}

function RecursiveSubmoduleUpdate($force) {
    if ($force) {  git submodule update --init --recursive --remote --force  }
    else        {  git submodule update --init --recursive --remote          }
}