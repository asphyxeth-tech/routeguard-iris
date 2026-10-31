# RouteGuard IRIS

RouteGuard is a new InterSystems IRIS Interoperability prototype for shipment-exception decisions. Synthetic carrier events travel through an IRIS Business Service, Business Process, and Business Operation. The process validates inputs, routes safety-sensitive events to human review, and records one durable recommendation per event ID. It never changes a real shipment or contacts a customer.

**Current status:** the core production and AI Hub adapter compile on the required IRIS AI Hub Community build 154. With no provider key, the production safely returns `REVIEW` with `Source=fallback`; policy, parser, and production tests pass. A **live model decision has not been run or verified**, so this is not yet a completed entry for the [AI Agents in Interoperability Workflows contest](https://community.intersystems.com/post/intersystems-programming-contest-ai-agents-interoperability-workflows).

## What runs today

```text
synthetic Exception → RouteGuard.Service.Intake
                    → RouteGuard.Process.Triage
                    → RouteGuard.Operation.Record → RouteGuard.Audit
```

The process rejects malformed events and returns a review recommendation without saving them. Temperature excursions and delays over 180 minutes receive a policy review route. Other events receive an explicit `fallback` review route while the AI Hub agent is unavailable. Duplicate event IDs return the original decision with `Replay=1` and do not call the operation again. The operation stores no personal data or payment information.

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

## EAP integration gate

The contest requires the AI Hub Community **build 154** image from InterSystems' sign-in-gated Early Access portal. The organizer says there is no public Docker Hub substitute and the image may not be redistributed. The exact x64 archive was obtained and loaded locally on October 31; Docker reports image `iris-community:2026.3.0AI.154.0` and IRIS reports version `2026.3.0AI.154.0com`. The separate EAP adapter uses an IRIS-native `%AI.Agent` with no tools, the `gpt-5-nano` model, `OPENAI_API_KEY` from the container environment, and a 200-output-token session cap. It sends only synthetic exception fields as JSON, then passes the model's strict JSON response through `RouteGuard.AI.ResponseParser` and the production's policy guard. The classes compile on build 154, but **no model call has been made**. A missing key fails closed to the production's REVIEW fallback. Do not claim this current fallback is an AI decision.

For x64, the required archive is named **`iris-community-2026.3.0AI.154.0-docker.tar.gz`**. The similar `iris-2026.3.0AI.154.0-docker.tar.gz` archive is the non-Community edition and is not the contest image. Once the Community archive is available, load it locally, use the image name printed by Docker as `<loaded-image>`, and tag it for the EAP Compose file:

```powershell
docker image load -i <path-to-iris-community-2026.3.0AI.154.0-docker.tar.gz>
docker tag <loaded-image> iris-community:2026.3.0AI.154.0
docker compose up -d
docker compose exec -T iris sh -lc 'iris session IRIS -U USER < /opt/routeguard/scripts/compile-core.mac'
docker compose exec -T iris sh -lc 'iris session IRIS -U USER < /opt/routeguard/scripts/compile-eap.mac'
docker compose exec -T iris sh -lc 'iris session IRIS -U USER < /opt/routeguard/scripts/test-production.mac'
docker compose exec -T iris sh -lc 'iris session IRIS -U USER < /opt/routeguard/scripts/test-ai-no-key.mac'
```

`compose.yaml` is the default contest startup and `compose.eap.yml` keeps the same EAP settings for explicit use. Both refuse a registry pull and expose the local Management Portal on `127.0.0.1:52773`. Startup and compilation were verified on build 154: `LOAD_STATUS=1`, `EAP_LOAD_STATUS=1`, `AI_AGENT_CLASS=1`, `AI_DECIDER_CLASS=1`. With `OPENAI_API_KEY` unset, `test-production.mac` exits 0 and `test-ai-no-key.mac` confirms `NO_KEY_ROUTE=REVIEW`, `NO_KEY_SOURCE=fallback`, and `ROUTEGUARD_NO_KEY_EXIT=0`. The live model path remains unverified. The test double must be removed before compiling the EAP adapter. Do not commit the archive, a derived image, license, provider key, or `.env` file. Judges use their own provider key.

After build 154 is loaded and a model key/cost limit are approved, copy `.env.example` to `.env` and set `OPENAI_API_KEY` locally. Recreate the container before the live test: a plain `docker compose restart` does not update container environment variables, and recreation may lose the compiled classes, so compile both source trees again. Keep the key out of logs and screenshots.

```powershell
docker compose up -d --force-recreate
docker compose exec -T iris sh -lc 'iris session IRIS -U USER < /opt/routeguard/scripts/compile-core.mac'
docker compose exec -T iris sh -lc 'iris session IRIS -U USER < /opt/routeguard/scripts/compile-eap.mac'
```

Then run one synthetic live decision and check for `ROUTEGUARD_AI_LIVE_EXIT=0` plus `AI_LIVE_SOURCE=ai`:

```powershell
docker compose exec -T iris sh -lc 'iris session IRIS -U USER < /opt/routeguard/scripts/test-ai-live.mac'
```

This command has **not** been run. The program will call the provider once, so it is not part of the free core test suite. The `RouteGuard.Test.LiveAI` class is compiled only from `eap/src` on the correct image. With `.env` still blank, the preceding no-key commands verify the `REVIEW` fallback without a provider call. A model or parser error should keep `Source=fallback`; those states still need testing before contest submission.

The contest application also needs a public open-source repository, a clean setup on build 154, and an Open Exchange submission by November 8, 2026 at 23:59 EST. No prize or payout has been received.
