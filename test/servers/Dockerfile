FROM library/node:17.7.2
WORKDIR /servers
COPY test/servers/package*.json .
RUN npm ci
COPY test/servers/. .
COPY test/proto ./proto