echo "Updating go dependencies..."
(
    cd src
    go get go@latest
    go get -u ./...
    go mod tidy
)
echo "You can commit the diffs now."
