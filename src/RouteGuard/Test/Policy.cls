/// Focused, synthetic checks for RouteGuard's input and output guardrails.
Class RouteGuard.Test.Policy Extends %RegisteredObject
{

ClassMethod Example() As RouteGuard.Message.Exception
{
    Set event = ##class(RouteGuard.Message.Exception).%New()
    Set event.EventId = "evt-policy-1"
    Set event.ShipmentId = "ship-100"
    Set event.EventType = "DELAY"
    Set event.DelayMinutes = 35
    Set event.CarrierNote = "The loading bay is temporarily closed."
    Set event.AlternateAvailable = 1
    Quit event
}

ClassMethod Run() As %Integer
{
    Set failures = 0
    Set event = ..Example()
    Set sc = ##class(RouteGuard.Policy).Validate(event)
    If $System.Status.IsError(sc) { Write "FAIL valid event",! Set failures = failures + 1 }

    Set event.EventId = ""
    Set sc = ##class(RouteGuard.Policy).Validate(event)
    If $System.Status.IsOK(sc) { Write "FAIL blank event ID",! Set failures = failures + 1 }
    Set event.EventId = "evt-policy-1"

    Set event.DelayMinutes = -1
    Set sc = ##class(RouteGuard.Policy).Validate(event)
    If $System.Status.IsOK(sc) { Write "FAIL negative delay",! Set failures = failures + 1 }
    Set event.DelayMinutes = 35

    Set event.EventType = "UNKNOWN"
    Set sc = ##class(RouteGuard.Policy).Validate(event)
    If $System.Status.IsOK(sc) { Write "FAIL unknown type",! Set failures = failures + 1 }
    Set event.EventType = "DELAY"

    Set event.EventType = "TEMPERATURE_EXCURSION"
    Set sc = ##class(RouteGuard.Policy).HardRoute(event, .route, .reason)
    If route '= "REVIEW" { Write "FAIL temperature hard route",! Set failures = failures + 1 }
    Set event.EventType = "DELAY"
    Set event.DelayMinutes = 181
    Set sc = ##class(RouteGuard.Policy).HardRoute(event, .route, .reason)
    If route '= "REVIEW" { Write "FAIL long delay hard route",! Set failures = failures + 1 }
    Set event.DelayMinutes = 35
    Set sc = ##class(RouteGuard.Policy).HardRoute(event, .route, .reason)
    If route '= "" { Write "FAIL ambiguous event hard route",! Set failures = failures + 1 }

    Set sc = ##class(RouteGuard.Policy).NormalizeAgentChoice(event, "EXPEDITE", "Alternate carrier can meet the promise.", .route, .reason)
    If route '= "EXPEDITE" { Write "FAIL valid expedite",! Set failures = failures + 1 }
    Set event.AlternateAvailable = 0
    Set sc = ##class(RouteGuard.Policy).NormalizeAgentChoice(event, "EXPEDITE", "Try another carrier.", .route, .reason)
    If route '= "REVIEW" { Write "FAIL unsupported expedite",! Set failures = failures + 1 }
    Set sc = ##class(RouteGuard.Policy).NormalizeAgentChoice(event, "DROP", "Invalid model output.", .route, .reason)
    If route '= "REVIEW" { Write "FAIL unknown agent route",! Set failures = failures + 1 }

    Write "POLICY_TEST_FAILURES=", failures, !
    Quit failures
}

}
