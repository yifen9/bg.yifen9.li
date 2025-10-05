FROM oven/bun:latest
ENV PATH=/root/.juliaup/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV JULIA_DEPOT_PATH=/opt/julia-depot
RUN mkdir -p /opt/julia-depot
RUN apt-get update && apt-get install -y ca-certificates git curl
RUN curl -fsSL https://install.julialang.org | sh -s -- -y && ~/.juliaup/bin/juliaup default release
RUN julia --project=/workspace -e 'using Pkg; Pkg.add(["YAML","JSON3","Glob"]); Pkg.precompile()'
WORKDIR /workspace