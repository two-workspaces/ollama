# Deploy and Host Ollama on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/ollama-production?referralCode=sLjDXb&utm_medium=integration&utm_source=button&utm_campaign=ollama-production)

[Ollama](https://github.com/ollama/ollama) runs open large language models (Llama, Qwen, Gemma, Mistral, DeepSeek and hundreds more) on your own server, with its own API and an OpenAI-compatible one. This template pairs a CPU build of Ollama, tuned for Railway, with [Open WebUI](https://github.com/open-webui/open-webui) for a ChatGPT-style chat in the browser. Your prompts and documents never leave your Railway project.

## About Hosting Ollama

Two services, each with a Railway volume.

- **Built for Railway's CPUs.** Railway has no GPUs, so this image is the official Ollama release with the GPU libraries removed: about 100 MB instead of 3.8 GB, so it builds and starts in seconds. It also caps the model's threads at your plan's vCPUs. Without the cap, llama.cpp sizes itself to the host's cores rather than your share of them; in our tests `llama3.2:3b` generated about 12 tokens/s with 24 threads and 55–80 tokens/s with the cap.
- **The API is locked.** Ollama has no authentication of its own, and a public Ollama URL is free compute for anyone who finds it. Here the public URL only answers requests that carry `Authorization: Bearer <OLLAMA_API_KEY>`. Open WebUI talks to Ollama over Railway's private network.
- **Idle costs almost nothing.** Railway counts cached files as memory. While no model is loaded, the server drops the cached model files, so an idle Ollama uses about 35 MB instead of the size of your models.
- **Ready on first boot.** A small chat model (`llama3.2:3b`) and an embedding model (`nomic-embed-text`) are pulled automatically. The Open WebUI admin account is created for you and public sign-up is closed.

## Common Use Cases

- A private ChatGPT for yourself or your team, with document chat (RAG) included
- A local LLM endpoint for n8n, Flowise, Langflow, Dify or your own code, with no per-token bill
- Testing open models before choosing one for a product

## Dependencies for Ollama Hosting

- Nothing else: models download from the Ollama library and are stored on the volume

### Deployment Dependencies

- [Ollama on GitHub](https://github.com/ollama/ollama)
- [Ollama model library](https://ollama.com/library)
- [Ollama API reference](https://github.com/ollama/ollama/blob/main/docs/api.md)
- [Open WebUI documentation](https://docs.openwebui.com)
- [Template source on GitHub](https://github.com/two-workspaces/ollama)

### Implementation Details

**Sign in to the chat.** Open the Open WebUI service's domain and sign in with `WEBUI_ADMIN_EMAIL` and `WEBUI_ADMIN_PASSWORD` from its Variables tab. Change the email and password in Settings > Account afterwards. Invite teammates from Admin Panel > Users.

**Use the API.** Send the key from the Ollama service's Variables tab as a Bearer token:

```bash
curl https://<your-ollama>.up.railway.app/api/generate \
  -H "Authorization: Bearer <OLLAMA_API_KEY>" \
  -d '{"model": "llama3.2:3b", "prompt": "Why is the sky blue?", "stream": false}'
```

The OpenAI-compatible endpoint is `https://<your-ollama>.up.railway.app/v1` with the same key, so any OpenAI client library works. Apps in the same Railway project can skip the key and call `http://${{Ollama.RAILWAY_PRIVATE_DOMAIN}}:11434` directly; that traffic isn't billed as egress.

**Add models.** Add names to `OLLAMA_PULL_MODELS` (comma-separated, e.g. `llama3.2:3b,nomic-embed-text,qwen3.5:4b`) and redeploy, or pull them from Open WebUI under Admin Panel > Settings > Models. On CPU, models up to about 4B parameters are comfortable; 7–9B models work but answer several times slower.

**Speed and memory.** The first request after an idle period loads the model from the volume (about 30 seconds for `llama3.2:3b`); after that, answers stream at 55–80 tokens/s on 8 vCPUs. A loaded model stays in memory for 5 minutes. Set `OLLAMA_KEEP_ALIVE=-1` on the Ollama service to keep it loaded permanently, at the cost of its RAM.

**Resources and cost.** Measured on Railway: Ollama idles at about 35 MB and uses roughly the model's size plus 1–2 GB while a model is loaded (about 5 GB with `llama3.2:3b`). Open WebUI idles at about 770 MB. You need the Hobby plan or higher. The default models take about 2.3 GB of the 5 GB Hobby volume.

**Threads.** `OLLAMA_NUM_THREADS` is left empty so the server reads your CPU quota at boot (the start-up log prints "Using N CPU threads"). Set it only to give Ollama fewer threads than your plan allows.

**Updates.** To change Ollama's version, add an `OLLAMA_VERSION` variable (e.g. `0.40.6`) to the Ollama service and redeploy; it's passed to the Dockerfile as a build argument. Open WebUI's version is its image tag. Models, chats and settings are stored on the volumes and survive updates.

## Why Deploy Ollama on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Ollama on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
