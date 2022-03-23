# protocurl

todo

# Usage
```
docker build -f src/Dockerfile -t protocurl:v1 src
```

# Installation

```
docker build -f src/Dockerfile -t protocurl:v1 .
```

# Dev Setup

...

run node server cli when installing new packages etc:

```
docker run -v "$PWD/test/servers:/servers" -it nodeserver:v1 /bin/bash
```

Build node server image:

```
docker build -t nodeserver:v1 -f test/servers/Dockerfile .
```

Run node server:

```
docker-compose -f test/servers/compose.yml up server
```

Run all tests (unix bash only):

```bash
./test/suite/test.sh
```

# How to contribute

...