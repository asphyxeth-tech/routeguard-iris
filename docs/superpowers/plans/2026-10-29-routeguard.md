# RouteGuard IRIS Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a runnable IRIS Interoperability shipment-exception prototype and later verify an AI Hub agent decision on EAP build 154.

**Architecture:** Original ObjectScript message classes feed a Business Service, Business Process, and Business Operation. The process validates events, uses an agent adapter only for ambiguous cases, enforces post-decision guardrails, and stores an idempotent audit record.

**Tech Stack:** InterSystems IRIS 2026.3 Community for core tests; EAP AI Hub build 154 for final agent tests; ObjectScript; Docker Compose.

**Spec:** `docs/superpowers/specs/2026-10-29-routeguard-design.md`

## Global Constraints

- Do not copy code from reference repositories or Devon's existing projects.
- No personal data or real shipment actions.
- Contest EAP image is login-gated and must never be redistributed.
- Core tests on public IRIS do not prove AI Hub integration.

## Review Focus

- Duplicate event ID must not produce a second audit row or agent call.
- Invalid shipment IDs, event types, negative or implausible delays must fail closed.
- Temperature excursions and delays over 180 minutes must route to review without model autonomy.
- Agent output outside the allowed enum or an unsupported expedite must route to review.
- Missing AI configuration must be visible as a safe fallback, not mislabeled as an agent decision.

---

### Task 1: Message and policy core

**Files:** `src/RouteGuard/Message/Exception.cls`, `src/RouteGuard/Message/Decision.cls`, `src/RouteGuard/Policy.cls`, `src/RouteGuard/Test/Policy.cls`.

**Interfaces:** `RouteGuard.Policy.Validate(exception)` returns status; `RouteGuard.Policy.HardRoute(exception, ByRef route, ByRef reason)` fills a route only for hard guards; `RouteGuard.Policy.NormalizeAgentChoice(exception, route, reason, ByRef finalRoute, ByRef finalReason)` enforces the output enum and expedite constraint.

- [x] Write policy tests for invalid input, hard-route cases, valid agent choices, and blocked expedite.
- [x] Run tests in public IRIS and see expected failure before the classes exist.
- [x] Implement messages and policy methods.
- [x] Compile in public IRIS and run focused tests to green.

### Task 2: Interoperability and audit

**Files:** `src/RouteGuard/Audit.cls`, `src/RouteGuard/Service/Intake.cls`, `src/RouteGuard/Process/Triage.cls`, `src/RouteGuard/Operation/Record.cls`, `src/RouteGuard/Production.cls`, `src/RouteGuard/Test/Production.cls`.

**Interfaces:** `RouteGuard.Service.Intake.OnProcessInput` forwards an Exception; `RouteGuard.Process.Triage.OnRequest` returns a Decision; `RouteGuard.Operation.Record.OnMessage` persists a single Audit row per EventId.

- [x] Write integration tests for event routing, duplicate replay, and one audit row.
- [x] Compile and run tests red on public IRIS.
- [x] Implement the BS/BP/BO production and explicit no-AI fallback.
- [x] Start the production and run integration tests green on public IRIS.

### Task 3: AI Hub agent adapter (requires EAP build 154)

**Files:** `src/RouteGuard/AI/Decider.cls`, `src/RouteGuard/Test/AI.cls`, `.env.example`, `README.md`.

**Interfaces:** `RouteGuard.AI.Decider.Decide(exception, ByRef route, ByRef reason)` uses `%AI.Provider` and `%AI.Agent` to select a bounded recommendation.

- [ ] Obtain build 154 through the operator's authorized EAP portal and load it locally; never publish its image.
- [ ] Write and run a failing live AI Hub integration test with a cost-limited provider key.
- [ ] Implement the AI Hub adapter and wire it into the process.
- [ ] Run the live test and a no-key safe-fallback test; document actual model usage and cost.

### Task 4: Submission readiness

**Files:** `Dockerfile`, `docker-compose.yml`, `README.md`, demo assets.

- [ ] Verify clean `docker compose up` on build 154 and all demo cases.
- [ ] Publish an original open-source repository with the exact EAP load/retag setup, but no image or secrets.
- [ ] Submit to Open Exchange and apply to the contest before November 8, after the human operator reviews any binding account or contest terms.
- [ ] Record any verified prize only when a payout or platform balance is observed.
