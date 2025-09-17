FROM library/node:17.7.2
# Keep this version in sync with release.yml
WORKDIR /servers
COPY test/servers/package*.json ./
RUN npm ci --ignore-scripts
COPY test/servers/. .
COPY test/proto ./proto
# When updating this setup, we also need to adapt the windows-test-server.ps1
# since that is used for the windows ci.