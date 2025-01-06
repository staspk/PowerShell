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
    $configFile = "$path\.git\config"
    if (-not(TestPathSilently $configFile)) {  WriteRed "No .git config file found under `$path: $path"; Return; }

    $url = git config --file $configFile --get remote.origin.url

    Start-Process $url
}