$ErrorActionPreference = "Stop"

# Run this script with "test" as the working directory

npm install -g forever

Write-Output "Install server..."
# Replicate steps from Dockerfile
cd servers
npm ci
node ./node_modules/typescript/bin/tsc

Write-Output "Before start server:"
ls dist
cd ..

Write-Output "Starting server..."
# runs in background
forever start ./servers/dist/server.js
Start-Sleep -s 8

if (Get-Command 'Get-NetTCPConnection' -errorAction SilentlyContinue) {
    Write-Output "Check server is running at 8080..."
    Get-Process -Id (Get-NetTCPConnection -LocalPort 8080).OwningProcess
}
else {
    Write-Output "I don't know how to check if the server is ready. Let's be lucky!"
}