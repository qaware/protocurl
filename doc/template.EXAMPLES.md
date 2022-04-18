# Examples

After starting the local test server via `docker-compose -f test/servers/compose.yml up --build server`, you can send
the following list of requests via protoCURL.

Each request needs to mount the directory of proto files into the containers `/proto` path to ensure, that they are
visible inside the docker container.

```
___EXAMPLE_1___
```

```
___EXAMPLE_2___
```

```
___EXAMPLE_3___
```

protoCURL also handles JSON:

```
___EXAMPLE_JSON___
```

Use `-q` to show the text format output only.

```
___EXAMPLE_OUTPUT_ONLY___
```

With `-q` all errors are written to stderr making it ideal for piping in scripts. Hence this request against a non-existing endpoint

```
___EXAMPLE_OUTPUT_ONLY_WITH_ERR_1___
```

will produce no output and only show this error:

```
___EXAMPLE_OUTPUT_ONLY_WITH_ERR_2___
```

Use `-v` for verbose output:

```
___EXAMPLE_4___
```
