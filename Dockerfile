FROM oven/bun:latest

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH=/root/.juliaup/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV JULIA_DEPOT_PATH=/opt/julia-depot

RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    apt-get update && apt-get install -y --no-install-recommends ca-certificates git curl \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://install.julialang.org | sh -s -- -y && ~/.juliaup/bin/juliaup default release

RUN mkdir -p /opt/julia-depot

WORKDIR /workspace
