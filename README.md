# RouteGuard IRIS

RouteGuard is a new InterSystems IRIS Interoperability prototype for shipment-exception decisions. Synthetic carrier events travel through an IRIS Business Service, Business Process, and Business Operation. The process validates inputs, routes safety-sensitive events to human review, and records one durable recommendation per event ID. It never changes a real shipment or contacts a customer.

**Current status:** the core production and native AI Hub adapter compile on the required IRIS AI Hub Community build 154. A free **local Ollama** model made a live synthetic decision through the IRIS production, and the route, reason, and source matched the durable audit record. The no-provider fallback and deterministic tests also pass. The app has **not** been published or submitted to the [AI Agents in Interoperability Workflows contest](https://community.intersystems.com/post/intersystems-programming-contest-ai-agents-interoperability-workflows); no prize or payout exists.

## What runs today

```text
synthetic Exception → RouteGuard.Service.Intake
                    → RouteGuard.Process.Triage
                    → RouteGuard.Operation.Record → RouteGuard.Audit
```

The process rejects malformed events and returns a review recommendation without saving them. Temperature excursions and delays over 180 minutes receive a policy review route without a model call. Other valid events use the AI Hub agent when `ROUTEGUARD_AI_PROVIDER=ollama`; malformed responses, model errors, or a disabled provider safely become `REVIEW` with `Source=fallback`. Post-decision guardrails can override a model recommendation and mark `Source=guardrail`. Duplicate event IDs return the original decision with `Replay=1` and do not call the agent or operation again. The operation stores no personal data or payment information.

## Run the verified core

The public `2026.3-zpm` image currently fails its own post-startup Python wrapper on this machine. `compose.core.yml` starts IRIS directly for local core testing. This development image does **not** include AI Hub.

```powershell
docker compose -f compose.core.yml up -d
docker compose -f compose.core.yml exec -T iris sh -lc 'iris session IRIS -U USER < /opt/routeguard/scripts/compile-core.mac'
docker compose -f compose.core.yml exec -T iris sh -lc 'iris session IRIS -U USER < /opt/routeguard/scripts/test-policy.mac'
docker compose -f compose.core.yml exec -T iris sh -lc 'iris session IRIS -U USER < /opt/routeguard/scripts/test-production.mac'
```

The last three commands must print `LOAD_STATUS=1`, `ROUTEGUARD_POLICY_EXIT=0`, and `ROUTEGUARD_PRODUCTION_EXIT=0`, respectively, with no ObjectScript exception. `iris session` can exit with code 0 even after a method error, so check the markers and output rather than relying on the shell exit code alone.

The parser runs without a model or key:

```powershell
docker compose -f compose.core.yml exec -T iris sh -lc 'iris session IRIS -U USER < /opt/routeguard/scripts/test-ai-parser.mac'
```

It must print `ROUTEGUARD_AI_PARSER_EXIT=0`. To test the production's agent boundary without calling an LLM, temporarily load the clearly labeled synthetic decider, run the seam tests, and remove it. Stop the production before switching between a test double and a real adapter:

```powershell
docker compose -f compose.core.yml exec -T iris sh -lc 'iris session IRIS -U USER < /opt/routeguard/scripts/stop-production.mac'
docker compose -f compose.core.yml exec -T iris sh -lc 'iris session IRIS -U USER < /opt/routeguard/scripts/load-ai-test-double.mac'
docker compose -f compose.core.yml exec -T iris sh -lc 'iris session IRIS -U USER < /opt/routeguard/scripts/test-ai-seam.mac'
docker compose -f compose.core.yml exec -T iris sh -lc 'iris session IRIS -U USER < /opt/routeguard/scripts/remove-ai-test-double.mac'
docker compose -f compose.core.yml exec -T iris sh -lc 'iris session IRIS -U USER < /opt/routeguard/scripts/stop-production.mac'
docker compose -f compose.core.yml exec -T iris sh -lc 'iris session IRIS -U USER < /opt/routeguard/scripts/test-production.mac'
```

The load, seam, and delete scripts must print `TEST_DOUBLE_LOAD_STATUS=1`, `ROUTEGUARD_AI_SEAM_EXIT=0`, and `TEST_DOUBLE_DELETE_STATUS=1`. The seam test checks valid CONTACT, duplicate replay without a second decider call, blocked EXPEDITE, unknown route, decider error, and hard policy bypass. A normalized override is labeled `guardrail`, a failed decider is labeled `fallback`, and a valid decider route is labeled `ai`. This is only a deterministic test of the production wiring, not an AI Hub result.

When changing a Business Process or Operation after the production has started, stop it before recompiling so the worker does not keep the old routine in memory:

```powershell
docker compose -f compose.core.yml exec -T iris sh -lc 'iris session IRIS -U USER < /opt/routeguard/scripts/stop-production.mac'
```

Stop the development container with `docker compose -f compose.core.yml stop --timeout 30`; the Compose entrypoint asks IRIS to shut down cleanly.

## Key-free AI Hub setup

The contest requires the AI Hub Community **build 154** image from InterSystems' sign-in-gated Early Access portal. The organizer says there is no public Docker Hub substitute and the image may not be redistributed. The exact x64 archive was obtained and loaded locally on October 31; Docker reports image `iris-community:2026.3.0AI.154.0` and IRIS reports version `2026.3.0AI.154.0com`. The separate EAP adapter uses an IRIS-native `%AI.Agent` with no tools, the local [Qwen2.5 7B](https://ollama.com/library/qwen2.5:7b) model, and a 200-output-token session cap. It sends only synthetic exception fields as JSON, then passes the model's response through `RouteGuard.AI.ResponseParser` and the independent production policy guard. [InterSystems documents this Ollama pattern](https://community.intersystems.com/post/my-first-agent-studio-building-and-testing-native-iris-agents-ai-hub-and-ollama). The local mode uses the nonsecret placeholder `api_key="ollama"` required by the OpenAI-compatible client; it does not read or require `OPENAI_API_KEY`.

For x64, the required archive is named **`iris-community-2026.3.0AI.154.0-docker.tar.gz`**. The similar `iris-2026.3.0AI.154.0-docker.tar.gz` archive is the non-Community edition and is not the contest image. Download the required archive through InterSystems' portal; it is **never** committed to this repo. Load it locally, use the image name printed by Docker as `<loaded-image>`, and tag it for Compose. Ollama's public image and model download separately into a local Docker volume:

```powershell
docker image load -i <path-to-iris-community-2026.3.0AI.154.0-docker.tar.gz>
docker tag <loaded-image> iris-community:2026.3.0AI.154.0
docker compose pull ollama
docker compose up -d
docker compose exec -T ollama ollama pull qwen2.5:7b
docker compose exec -T iris sh -lc 'iris session IRIS -U USER < /opt/routeguard/scripts/compile-core.mac'
docker compose exec -T iris sh -lc 'iris session IRIS -U USER < /opt/routeguard/scripts/compile-eap.mac'
docker compose exec -T iris sh -lc 'iris session IRIS -U USER < /opt/routeguard/scripts/test-production.mac'
docker compose exec -T iris sh -lc 'iris session IRIS -U USER < /opt/routeguard/scripts/test-ai-no-key.mac'
```

`compose.yaml` is the default contest startup and `compose.eap.yml` keeps the same EAP settings for explicit use. Both refuse a registry pull of the EAP image. The Ollama service is reachable only on the private Compose network and the host's `127.0.0.1:11434`; the IRIS Management Portal uses `127.0.0.1:52773`. Startup and compilation were verified on build 154: `LOAD_STATUS=1`, `EAP_LOAD_STATUS=1`, `AI_AGENT_CLASS=1`, `AI_DECIDER_CLASS=1`. The default `ROUTEGUARD_AI_PROVIDER=none` makes `test-production.mac` exit 0 and `test-ai-no-key.mac` confirm `NO_KEY_ROUTE=REVIEW`, `NO_KEY_SOURCE=fallback`, and `ROUTEGUARD_NO_KEY_EXIT=0` without a model call. The test double must be removed before compiling the EAP adapter. Do not commit either image, the model weights, EAP license material, a provider key, or `.env`.

For a **key-free live run**, copy `.env.example` to `.env` (which is gitignored). It selects `ROUTEGUARD_AI_PROVIDER=ollama` and `OLLAMA_MODEL=qwen2.5:7b` with `OPENAI_API_KEY` blank. Recreate the IRIS container after changing the provider mode: a plain `docker compose restart` does not update container environment variables, and recreation loses compiled classes, so compile both source trees again. The Ollama volume retains the downloaded model.

```powershell
docker compose up -d --force-recreate --no-deps iris
docker compose exec -T iris sh -lc 'iris session IRIS -U USER < /opt/routeguard/scripts/compile-core.mac'
docker compose exec -T iris sh -lc 'iris session IRIS -U USER < /opt/routeguard/scripts/compile-eap.mac'
docker compose exec -T iris sh -lc 'iris session IRIS -U USER < /opt/routeguard/scripts/test-local-provider-init.mac'
```

Then run one synthetic live decision and check for `ROUTEGUARD_AI_LIVE_EXIT=0` plus `AI_LIVE_SOURCE=ai`:

```powershell
docker compose exec -T iris sh -lc 'iris session IRIS -U USER < /opt/routeguard/scripts/test-ai-live.mac'
```

The local live command was run on build 154 and returned `AI_LIVE_ROUTE=EXPEDITE`, `AI_LIVE_SOURCE=ai`, `AI_LIVE_TEST_FAILURES=0`, and `ROUTEGUARD_AI_LIVE_EXIT=0`. It checked that the final route, source, and reason match a durable `RouteGuard.Audit` row. Ollama's logs independently show HTTP 200 `POST /v1/chat/completions` from the IRIS container. [The run record](docs/local-ai-evidence-2026-10-31.md) gives the model digest, timings, test sequence, resources, and limits. The provider is local and incurs no API charge. A future cloud-provider mode remains optional and must use an owner-approved key and cost cap; it was not used here.

The contest application also needs a public open-source repository, a clean setup on build 154, and an Open Exchange submission by November 8, 2026 at 23:59 EST. No prize or payout has been received.
