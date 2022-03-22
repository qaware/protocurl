# protocurl

todo

# Usage

...

# Installation

...

# Dev Setup

...

run node server cli when installing new packages etc:

```
docker run -v "$PWD/test/servers:/servers" -it nodeserver:v1 /bin/bash
```

Build node server image:

```
docker build -t nodeserver:v1 --progress plain -f test/servers/Dockerfile test/servers
```

Run node server:

```
docker-compose -f test/servers/compose.yml up server
```

# How to contribute

...