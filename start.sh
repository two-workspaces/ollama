#!/bin/bash
set -e
[ -n "$OLLAMA_API_KEY" ] || { echo "OLLAMA_API_KEY must be set" >&2; exit 1; }

# Thread count = the container's CPU quota (cgroup v2), unless set by hand.
if [ -z "$OLLAMA_NUM_THREADS" ]; then
  read -r quota period < /sys/fs/cgroup/cpu.max 2>/dev/null || quota=max
  if [ "$quota" != max ]; then
    OLLAMA_NUM_THREADS=$(( (quota + period - 1) / period ))
  else
    OLLAMA_NUM_THREADS=$(nproc)
  fi
fi
export OLLAMA_NUM_THREADS
echo "Using $OLLAMA_NUM_THREADS CPU threads"

ollama serve &
ollama_pid=$!
caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &
caddy_pid=$!

if [ -n "$OLLAMA_PULL_MODELS" ]; then
  (
    until OLLAMA_HOST=127.0.0.1:11434 ollama list >/dev/null 2>&1; do sleep 1; done
    for m in ${OLLAMA_PULL_MODELS//,/ }; do
      echo "Pulling $m"
      OLLAMA_HOST=127.0.0.1:11434 ollama pull "$m" >/dev/null 2>&1 && echo "Pulled $m" || echo "Pull of $m failed"
    done
  ) &
fi

# Exit as soon as Ollama or Caddy dies so Railway restarts the container.
wait -n "$ollama_pid" "$caddy_pid"
