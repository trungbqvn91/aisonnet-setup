FROM ubuntu:24.04
RUN apt-get update && apt-get install -y --no-install-recommends bash shellcheck python3 python3-venv curl ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /repo
CMD ["bash", "tests/linux/run.sh"]
