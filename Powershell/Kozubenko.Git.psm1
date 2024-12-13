using module ".\Kozubenko.Utils.psm1"

function GitConfig ($email, $name) {
    git config --global user.email $email
    git config --global user.name $name
}

function Push ($commitMsg = "No Commit Message") {
    git add .
    git commit -a -m $commitMsg
    git push
}

function Github ($path = $PWD.Path) {
    if (-not(TestPathSilently "$path\.git")) {
        Write-Host "No .git file in given `$path == '$path'"
    }
    $configFile = "$path\.git\"
}

Export-ModuleMember -Function GitConfig, Push, Github