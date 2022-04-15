$ErrorActionPreference = "Stop"

# This script should be primarily run from CI.

$pc = $args[0]
$ExeExt = $args[1]

Write-Output "========= Running native tests ========="

function Run-Tests
{
    param(
        $ProtocurlExec
    )

    Write-Output "====== Running tests using executable $ProtocurlExec ======"

    Write-Output "=== Executable is runnable ==="
    &"$ProtocurlExec" -h

    Write-Output "=== Base scenario runs. protoc$ExeExt is found and used. protocurl-internal is found and used ==="
    &"$ProtocurlExec" -I test/proto `
    -f happyday.proto -i happyday.HappyDayRequest -o happyday.HappyDayResponse `
    -u http://localhost:8080/happy-day/verify -d "includeReason: true"

    Write-Output "=== Using custom protoc and proto lib and global curl ==="
    if (Test-Path my-protoc) {
        Remove-Item my-protoc -Recurse -force
    }
    mkdir my-protoc
    mkdir my-protoc/my-bin
    Copy-Item "$pc/protocurl-internal/bin/protoc$ExeExt" -Destination my-protoc/my-bin/protoc$ExeExt
    Copy-Item "$pc/protocurl-internal/include" -Destination my-protoc/my-protos -Recurse
    Copy-Item "test/proto/*" -Destination my-protoc/my-protos -Recurse

    &"$ProtocurlExec" -v --curl `
    --protoc-path my-protoc/my-bin/protoc -I my-protoc/my-protos `
    -f happyday.proto -i happyday.HappyDayRequest -o happyday.HappyDayResponse `
    -u http://localhost:8080/happy-day/verify -d "includeReason: true"
}

Run-Tests("./$pc/bin/protocurl$ExeExt")

Write-Output "Installing protocurl into PATH and re-executing..."

$EnvPathSeparator = "$( [IO.Path]::PathSeparator )"
# ; on windows, : on unix

$Env:PATH += "$EnvPathSeparator$PWD/$pc/bin"

Write-Output "Path after installation: $Env:PATH"

Run-Tests("protocurl")

Write-Output "========= Native Tests successful. ========="