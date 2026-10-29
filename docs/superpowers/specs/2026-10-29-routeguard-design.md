# RouteGuard IRIS contest design

## Intent and fit

Build an original InterSystems IRIS Interoperability production for the AI Agents in Interoperability Workflows contest. It receives synthetic shipment exceptions, lets an AI Hub agent choose a bounded next-step recommendation for ambiguous events, and records the decision in IRIS. It does not send messages to customers or change a real shipment. The design showcases IRIS message tracing, guardrails, idempotency, and auditability rather than a chat box.

The work is fresh for this income competition. It uses no code or concept from Devon's prior projects and does not reuse the new Website QA, VolunteerShift, or BountyProof products.

## Approaches considered

- A Python sidecar calling IRIS would be easy to code but make the required Interoperability workflow secondary.
- An MCP wrapper over a database would expose tools but resemble an existing registered entry and leave the decision outside the production.
- **Chosen:** native ObjectScript Business Service → Business Process → Business Operation. The process applies deterministic safety gates, invokes an AI Hub `%AI.Agent` only for ambiguous events, validates its structured decision, and persists the result. This directly serves the contest task.

## Workflow contract

1. A demo harness sends a synthetic `RouteGuard.Message.Exception` through `RouteGuard.Service.Intake`. Each event has an event ID, shipment ID, event type, delay minutes, carrier note, and whether an alternate route is available. No personal data is included.
2. Validation rejects malformed or out-of-range events. Duplicate event IDs return the recorded result without a second agent call.
3. A temperature excursion or delay over 180 minutes goes to `REVIEW` without model autonomy. Other valid exceptions go to the AI Hub agent for a choice among `CONTACT`, `EXPEDITE`, and `REVIEW`, with a short reason.
4. A post-agent guard rejects unknown output and prevents `EXPEDITE` unless an alternative route exists. Failures or missing AI configuration safely become `REVIEW` with an explicit source marker.
5. The Business Operation saves one audit row per event with the final route, reason, and source. It never performs an external shipment action.

## Development and submission gates

- The contest requires exact AI Hub EAP Community build 154, obtained from the sign-in-gated InterSystems portal. No matching image is currently installed. The public `intersystemsdc/iris-community:2026.3-zpm` image can compile and exercise only the non-AI core. Do not present this as a completed AI Hub entry until build 154 is obtained and a live agent decision is verified.
- The Early Access image must not be republished or included in a public repository; only Dockerfiles, Compose, source, and setup steps may be shared.
- No paid LLM call is made in development without explicit cost visibility. Judges may use their own key. A labeled replay mode can demonstrate wiring without claiming it is a live AI decision.
- The final contest app must be fully functional, open source, documented in English, and submitted by November 8, 2026 at 23:59 EST. A prize is not a receipt until paid.

## Non-goals

No real shipping integration, customer notification, payment, regulated goods, production use, or automatic physical-world action. No new user account or Terms acceptance in this development pass.
