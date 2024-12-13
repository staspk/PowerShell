using module .\Kozubenko.Utils.psm1

function GitConfig($email, $name) {
    git config --global user.email $email
    git config --global user.name $name
}

function Push($commitMsg = "No Commit Message") {
    git add .
    git commit -a -m $commitMsg
    git push
}

function Github($path = $PWD.Path) {
    $configFile = "$path\.git\config"
    if (-not(TestPathSilently $configFile)) {  Write-Host "No .git config file found under `$path: '$path'"; return; }

    $url = git config --get remote.origin.url
    Start-Process $url  
}