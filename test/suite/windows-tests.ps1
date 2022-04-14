# This script should be primarily run from CI.

$pc = $args[0]

Write-Output "========= Running windows specific tests ========="


Write-Output "=== Executable is runnable ==="
&"$pc\bin\protocurl.exe" -h


Write-Output "=== Base scenario runs. protoc.exe is found and used. protocurl-internal is found and used ==="
&"$pc\bin\protocurl.exe" -I test\proto `
    -f happyday.proto -i happyday.HappyDayRequest -o happyday.HappyDayResponse `
    -u http://localhost:8080/happy-day/verify -d "includeReason: true"


Write-Output "=== Using custom protoc and proto lib and global curl ==="
if (Test-Path my-protoc) {
    Remove-Item my-protoc -Recurse -force
}
mkdir my-protoc
mkdir my-protoc\my-bin
Copy-Item "$pc\protocurl-internal\bin\protoc.exe" -Destination my-protoc\my-bin\protoc.exe
Copy-Item "$pc\protocurl-internal\include" -Destination my-protoc\my-protos -Recurse
Copy-Item "test\proto\*" -Destination my-protoc\my-protos -Recurse
ls my-protoc\my-bin
ls my-protoc\my-protos

&"$pc\bin\protocurl.exe" -v --curl `
    --protoc-path my-protoc\my-bin\protoc -I my-protoc\my-protos `
    -f happyday.proto -i happyday.HappyDayRequest -o happyday.HappyDayResponse `
    -u http://localhost:8080/happy-day/verify -d "includeReason: true"

Write-Output "========= Windows Tests successful. ========="