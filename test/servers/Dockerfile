FROM library/node:17.7.2
WORKDIR /servers
COPY package*.json .
RUN npm ci
COPY * .