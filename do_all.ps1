function do_build(){
    param([string]$name,[string]$url)
    if (-not (Test-Path -Path $name -PathType Container)) {
        git clone --recursive $url 2>$null
        if (Test-Path -Path "_patches/$name.patch") {
            pushd $name
            git apply "../_patches/$name.patch"
            popd
        }
    }
}

function links(){
$T=@"
https://github.com/tihmstar/libgeneral.git
https://github.com/tihmstar/libfragmentzip.git
https://github.com/libimobiledevice/libplist.git
https://github.com/libimobiledevice/libimobiledevice-glue.git
https://github.com/libimobiledevice/libusbmuxd.git
https://github.com/libimobiledevice/libirecovery.git
https://github.com/libimobiledevice/libimobiledevice.git
https://github.com/nih-at/libzip.git
https://github.com/1Conan/tsschecker.git

https://github.com/lzfse/lzfse.git
https://github.com/tihmstar/img4tool.git
https://github.com/tihmstar/libinsn.git
https://github.com/Cryptiiiic/liboffsetfinder64.git
https://github.com/nyuszika7h/xpwn.git
https://github.com/Cryptiiiic/libipatcher.git
https://github.com/futurerestore/futurerestore.git

https://github.com/tihmstar/igetnonce.git
https://github.com/tihmstar/noncestatistics.git
"@
($T).replace("`r", "").split("`n")|Where-Object {$_ -ne ''}
}

function makeall(){
    $ROOT=Get-Location
    New-Item -ItemType Directory -Force -Path  "$ROOT\INST" | Out-Null
    $env:PKG_CONFIG_PATH = "$ROOT\INST\lib\pkgconfig"
    $env:LD_LIBRARY_PATH = "$ROOT\INST\lib"
    $env:LDFLAGS = "-L$ROOT\INST\lib -g"
    $env:CFLAGS = "-I$ROOT\INST\include -g"
    $env:CXXFLAGS = "-I$ROOT\INST\include -g"

    links | ForEach-Object {
        $repoName = $_ -replace '^.*/', ''
        $repoName = $repoName -replace '\.[^.]*$', ''
        echo "============= $repoName $_ ============"
        do_build $repoName $_
    }
}

$env:http_proxy = "http://192.168.1.2:8800"
$env:https_proxy = "http://192.168.1.2:8800"
makeall
