# Run this script with "test" as the working directory

npm install -g forever

Write-Output "Install server..."
# Replicate steps from Dockerfile
cd servers
npm ci
node .\node_modules\typescript\bin\tsc

Write-Output "Before start server:"
ls dist
cd ..

Write-Output "Starting server..."
# runs in background
forever start .\servers\dist\server.js
Start-Sleep -s 8

Write-Output "Check server is running at 8080..."
Get-Process -Id (Get-NetTCPConnection -LocalPort 8080).OwningProcess

