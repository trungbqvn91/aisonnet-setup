# Linux logic tests

Run from the repository root:

```bash
docker build -t aisonnet-linux tests/linux && docker run --rm -v "$PWD:/repo:ro" aisonnet-linux
```

The repository is mounted read-only. Tests write only to a temporary directory
inside the container.
