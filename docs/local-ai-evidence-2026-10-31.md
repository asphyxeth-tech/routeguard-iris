# RouteGuard local AI Hub verification — October 31, 2026

This is a point-in-time development record, not a contest acceptance or a real shipment decision. Every event was synthetic. The Early Access image and local model weights are **not** included in this repository.

## Environment

- InterSystems IRIS AI Hub Community x64 build `2026.3.0AI.154.0com`, loaded from the official Early Access archive `iris-community-2026.3.0AI.154.0-docker.tar.gz` and tagged locally as `iris-community:2026.3.0AI.154.0`. Local Docker image ID begins `sha256:8fc1e5c64ed7`.
- [Ollama's official Docker image](https://docs.ollama.com/docker), running on the same private Compose network. Its host port is bound only to `127.0.0.1:11434`.
- Local [Qwen2.5 7B](https://ollama.com/library/qwen2.5:7b), Ollama model digest `845dbda0ea48ed749caafd9e6037047aa19acfcfd82e704d7ca97d631a0b697e`, 4.7 GB stored in the Docker volume. The model page lists Apache 2.0. No model weights are committed or redistributed.
- `ROUTEGUARD_AI_PROVIDER=ollama`, `OLLAMA_MODEL=qwen2.5:7b`, `OPENAI_API_KEY` absent. AI Hub uses its OpenAI-compatible provider pointed at the local `http://ollama:11434/v1` endpoint with the nonsecret dummy value `api_key="ollama"`, following the [InterSystems local Ollama example](https://community.intersystems.com/post/my-first-agent-studio-building-and-testing-native-iris-agents-ai-hub-and-ollama) and [Ollama compatibility guide](https://docs.ollama.com/api/openai-compatibility). No cloud model, user credential, or provider fee was used.

## Verified checks

1. With the provider disabled, the exact Community build compiled all 13 core classes (`LOAD_STATUS=1`) and all three EAP classes (`EAP_LOAD_STATUS=1`; `AI_AGENT_CLASS=1`; `AI_DECIDER_CLASS=1`). Policy, JSON parser, and production tests each exited 0. The no-key test recorded `REVIEW`, `Source=fallback`, and `ROUTEGUARD_NO_KEY_EXIT=0` without a provider request.
   An optional `ROUTEGUARD_AI_PROVIDER=openai` initialization check with no key returned `OPENAI_API_KEY is not configured`, and an unknown provider mode returned `RouteGuard AI provider is disabled or unknown`; neither made a model call.
2. The local Ollama endpoint returned HTTP 200 to a synthetic OpenAI-compatible chat request. It returned a JSON object with `route="EXPEDITE"` and a reason. A warm request used 61 prompt and 37 completion tokens.
3. In local Ollama mode, the EAP classes recompiled and `test-local-provider-init.mac` returned `LOCAL_PROVIDER_INIT_STATUS=1`, model `qwen2.5:7b`. Core policy and parser tests exited 0. The first integrated `test-ai-live.mac` returned `AI_LIVE_ROUTE=EXPEDITE`, `AI_LIVE_SOURCE=ai`, and `ROUTEGUARD_AI_LIVE_EXIT=0`.
4. After temporarily replacing the compiled decider with a **synthetic test double**, the production seam test exited 0. The test double was removed, the real EAP classes recompiled, and another live AI Hub test exited 0. This confirms the final compiled decider was the real adapter, not the test double.
5. A final live synthetic event `evt-live-ai-F26E2BD7-D55C-11F1-91E5-66340261C37E` returned `EXPEDITE`, `Source=ai`, reason `Alternate route available to avoid delay.` The live test checked that the durable `RouteGuard.Audit` record had the same route, source, and reason; `AI_LIVE_TEST_FAILURES=0`.
6. Ollama service logs show HTTP 200 `POST /v1/chat/completions` from the IRIS container at 18:56:35 UTC (11.24 s), 18:57:18 UTC (2.55 s), and 18:57:42 UTC (2.28 s). These were local network calls. The local model's first cold load took longer; response time varies with hardware.

## Resource sample and limits

While the model was loaded, `docker stats --no-stream` reported about 9.1 GiB for Ollama and 0.8 GiB for IRIS inside a 15.22 GiB Docker VM. `ollama ps` reported a 5.1 GB loaded model on **100% CPU**. The host had approximately 32 GB physical RAM. These are measurements from one development run, not minimum system requirements.

The AI agent has no tools or shipment side effects. The model sees only the synthetic event type, delay, alternate-route flag, and carrier note. The parser requires a bounded JSON object; independent policy checks can override the route. Temperature excursions and long delays do not call the model. Duplicate event IDs replay the original audit decision. The demo does not prove performance, correctness, or safety on real carrier data. No contest award or payout has been received.
