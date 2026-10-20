# CPU-only Ollama for Railway: the official release minus the CUDA/ROCm/Vulkan
# libraries (Railway has no GPUs), behind a Caddy Bearer-token gate.
FROM ubuntu:24.04 AS fetch
ARG OLLAMA_VERSION=0.40.6
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl zstd \
 && mkdir /out && curl -fsSL "https://github.com/ollama/ollama/releases/download/v${OLLAMA_VERSION}/ollama-linux-amd64.tar.zst" \
  | zstd -d | tar -x -C /out --exclude='lib/ollama/cuda_*' --exclude='lib/ollama/vulkan' \
 && mv /out/lib/ollama/llama-server /out/lib/ollama/llama-server.real

FROM caddy:2.11.7 AS caddy

FROM ubuntu:24.04
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \
 && rm -rf /var/lib/apt/lists/*
COPY --from=fetch /out/bin/ollama /usr/bin/ollama
COPY --from=fetch /out/lib/ollama /usr/lib/ollama
COPY --from=caddy /usr/bin/caddy /usr/bin/caddy
COPY llama-server /usr/lib/ollama/llama-server
COPY Caddyfile /etc/caddy/Caddyfile
COPY start.sh /start.sh
ENV OLLAMA_HOST=[::]:11434 OLLAMA_MODELS=/root/.ollama/models PORT=8080
EXPOSE 8080 11434
ENTRYPOINT ["/start.sh"]
