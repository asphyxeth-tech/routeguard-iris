# RouteGuard IRIS

RouteGuard is a new InterSystems IRIS Interoperability prototype for shipment-exception decisions. Synthetic carrier events travel through an IRIS Business Service, Business Process, and Business Operation. The process validates inputs, routes safety-sensitive events to human review, and records one durable recommendation per event ID. It never changes a real shipment or contacts a customer.

**Current status:** the non-AI production is compiled and tested on the public IRIS 2026.3 Community image. The AI Hub agent adapter has **not** been implemented or tested. This is not yet a completed entry for the [AI Agents in Interoperability Workflows contest](https://community.intersystems.com/post/intersystems-programming-contest-ai-agents-interoperability-workflows).

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

When changing a Business Process or Operation after the production has started, stop it before recompiling so the worker does not keep the old routine in memory:

```powershell
docker compose -f compose.core.yml exec -T iris sh -lc 'iris session IRIS -U USER < /opt/routeguard/scripts/stop-production.mac'
```

## EAP integration gate

The contest requires the AI Hub Community **build 154** image from InterSystems' sign-in-gated Early Access portal. The organizer says there is no public Docker Hub substitute and the image may not be redistributed. Once the operator obtains it, add an AI Hub `%AI.Agent` adapter for ambiguous events, run a real decision with an operator-approved model key and cost cap, and document the exact image load/retag and model settings. A replay path may help judges explore the workflow without a key, but must be labeled as replay. Do not claim this current fallback is an AI decision.

The contest application also needs a public open-source repository, a clean setup on build 154, and an Open Exchange submission by November 8, 2026 at 23:59 EST. No prize or payout has been received.
