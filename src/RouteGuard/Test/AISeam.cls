/// Synthetic checks for the agent call boundary; never invokes an LLM.
Class RouteGuard.Test.AISeam Extends %RegisteredObject
{

ClassMethod Run() As %Integer
{
    Set failures = 0
    Set ^RouteGuardTest("AICalls") = 0
    Set sc = ##class(Ens.Director).GetProductionStatus(.productionName,.productionState)
    If $System.Status.IsError(sc) { Write "FAIL production status",! Quit 1 }
    If (productionState = 1),(productionName '= "RouteGuard.Production") { Write "FAIL another production is running",! Quit 1 }
    If (productionState '= 1) {
        Set sc = ##class(Ens.Director).StartProduction("RouteGuard.Production")
        If $System.Status.IsError(sc) { Write "FAIL start production",! Quit 1 }
    }
    Set sc = ##class(Ens.Director).CreateBusinessService("RouteGuard.Service.Intake",.service)
    If $System.Status.IsError(sc) { Write "FAIL create service",! Quit 1 }

    Set contact = ##class(RouteGuard.Test.Policy).Example()
    Set contact.EventId = "evt-ai-contact-"_$System.Util.CreateGUID()
    Set contact.CarrierNote = "STUB:CONTACT"
    Set sc = service.ProcessInput(contact,.decision)
    If $System.Status.IsError(sc) { Write "FAIL contact request",! Quit 1 }
    If '$IsObject(decision) { Write "FAIL missing contact decision",! Quit 1 }
    If decision.Route '= "CONTACT" { Write "FAIL agent contact route",! Set failures=failures+1 }
    If decision.Source '= "ai" { Write "FAIL agent contact source",! Set failures=failures+1 }
    If $Get(^RouteGuardTest("AICalls")) '= 1 { Write "FAIL first agent call count",! Set failures=failures+1 }
    Set audit = ##class(RouteGuard.Audit).%OpenId(contact.EventId)
    If '$IsObject(audit) { Write "FAIL missing contact audit",! Set failures=failures+1 }

    Set sc = service.ProcessInput(contact,.replay)
    If $System.Status.IsError(sc) { Write "FAIL replay request",! Quit 1 }
    If '$IsObject(replay) { Write "FAIL missing replay decision",! Quit 1 }
    If replay.Replay '= 1 { Write "FAIL replay marker",! Set failures=failures+1 }
    If replay.Route '= "CONTACT" { Write "FAIL replay route",! Set failures=failures+1 }
    If $Get(^RouteGuardTest("AICalls")) '= 1 { Write "FAIL replay called agent",! Set failures=failures+1 }

    Set noAlternate = ##class(RouteGuard.Test.Policy).Example()
    Set noAlternate.EventId = "evt-ai-no-alt-"_$System.Util.CreateGUID()
    Set noAlternate.AlternateAvailable = 0
    Set noAlternate.CarrierNote = "STUB:EXPEDITE"
    Set sc = service.ProcessInput(noAlternate,.guarded)
    If $System.Status.IsError(sc) { Write "FAIL guarded request",! Quit 1 }
    If '$IsObject(guarded) { Write "FAIL missing guarded decision",! Quit 1 }
    If guarded.Route '= "REVIEW" { Write "FAIL unsupported expedite route",! Set failures=failures+1 }
    If guarded.Source '= "guardrail" { Write "FAIL unsupported expedite source",! Set failures=failures+1 }

    Set unknown = ##class(RouteGuard.Test.Policy).Example()
    Set unknown.EventId = "evt-ai-unknown-"_$System.Util.CreateGUID()
    Set unknown.CarrierNote = "STUB:DROP"
    Set sc = service.ProcessInput(unknown,.invalid)
    If $System.Status.IsError(sc) { Write "FAIL invalid agent request",! Quit 1 }
    If '$IsObject(invalid) { Write "FAIL missing invalid agent decision",! Quit 1 }
    If invalid.Route '= "REVIEW" { Write "FAIL unknown agent route",! Set failures=failures+1 }
    If invalid.Source '= "guardrail" { Write "FAIL unknown agent source",! Set failures=failures+1 }

    Set broken = ##class(RouteGuard.Test.Policy).Example()
    Set broken.EventId = "evt-ai-error-"_$System.Util.CreateGUID()
    Set broken.CarrierNote = "STUB:ERROR"
    Set sc = service.ProcessInput(broken,.fallback)
    If $System.Status.IsError(sc) { Write "FAIL broken agent request",! Quit 1 }
    If '$IsObject(fallback) { Write "FAIL missing fallback decision",! Quit 1 }
    If fallback.Route '= "REVIEW" { Write "FAIL agent error route",! Set failures=failures+1 }
    If fallback.Source '= "fallback" { Write "FAIL agent error source",! Set failures=failures+1 }
    If $Find(fallback.Reason,"failed") = 0 { Write "FAIL agent error reason",! Set failures=failures+1 }

    Set callsBeforeHard = $Get(^RouteGuardTest("AICalls"))
    Set hard = ##class(RouteGuard.Test.Policy).Example()
    Set hard.EventId = "evt-ai-hard-"_$System.Util.CreateGUID()
    Set hard.EventType = "TEMPERATURE_EXCURSION"
    Set hard.CarrierNote = "STUB:CONTACT"
    Set sc = service.ProcessInput(hard,.policyDecision)
    If $System.Status.IsError(sc) { Write "FAIL hard route request",! Quit 1 }
    If '$IsObject(policyDecision) { Write "FAIL missing policy decision",! Quit 1 }
    If policyDecision.Source '= "policy" { Write "FAIL hard route source",! Set failures=failures+1 }
    If $Get(^RouteGuardTest("AICalls")) '= callsBeforeHard { Write "FAIL hard route called agent",! Set failures=failures+1 }

    Write "AI_SEAM_FAILURES=",failures,!
    Quit failures
}

}
