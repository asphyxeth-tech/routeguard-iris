/// Real Interoperability path checks on synthetic shipment events.
Class RouteGuard.Test.Production Extends %RegisteredObject
{

ClassMethod Run() As %Integer
{
    Set failures = 0
    Set sc = ##class(Ens.Director).GetProductionStatus(.productionName,.productionState)
    If $System.Status.IsError(sc) { Write "FAIL production status: ",$System.Status.GetErrorText(sc),! Quit 1 }
    If (productionState = 1),(productionName '= "RouteGuard.Production") { Write "FAIL another production is running",! Quit 1 }
    If (productionState '= 1) {
        Set sc = ##class(Ens.Director).StartProduction("RouteGuard.Production")
        If $System.Status.IsError(sc) { Write "FAIL start production: ",$System.Status.GetErrorText(sc),! Quit 1 }
    }
    Set sc = ##class(Ens.Director).CreateBusinessService("RouteGuard.Service.Intake", .service)
    If $System.Status.IsError(sc) { Write "FAIL create service: ",$System.Status.GetErrorText(sc),! Quit 1 }

    Set event = ##class(RouteGuard.Test.Policy).Example()
    Set event.EventId = "evt-integration-"_$SYSTEM.Util.CreateGUID()
    Set sc = service.ProcessInput(event, .decision)
    If $System.Status.IsError(sc) { Write "FAIL route event: ",$System.Status.GetErrorText(sc),! Quit 1 }
    If '$IsObject(decision) { Write "FAIL missing route response",! Quit 1 }
    If decision.Route '= "REVIEW" { Write "FAIL unavailable AI fallback route",! Set failures = failures + 1 }
    If decision.Source '= "fallback" { Write "FAIL unavailable AI fallback source",! Set failures = failures + 1 }
    Set firstCreated = ""
    Set audit = ##class(RouteGuard.Audit).%OpenId(event.EventId)
    If '$IsObject(audit) { Write "FAIL missing audit record",! Set failures = failures + 1 }
    If $IsObject(audit) Set firstCreated = audit.CreatedAt

    Set sc = service.ProcessInput(event, .replay)
    If $System.Status.IsError(sc) { Write "FAIL replay event: ",$System.Status.GetErrorText(sc),! Quit 1 }
    If '$IsObject(replay) { Write "FAIL missing replay response",! Quit 1 }
    If replay.Replay '= 1 { Write "FAIL replay marker",! Set failures = failures + 1 }
    Set audit = ##class(RouteGuard.Audit).%OpenId(event.EventId)
    If '$IsObject(audit) { Write "FAIL audit missing after replay",! Set failures = failures + 1 }
    If $IsObject(audit), audit.CreatedAt '= firstCreated { Write "FAIL duplicate audit overwrite",! Set failures = failures + 1 }

    Set hard = ##class(RouteGuard.Test.Policy).Example()
    Set hard.EventId = "evt-temperature-"_$SYSTEM.Util.CreateGUID()
    Set hard.EventType = "TEMPERATURE_EXCURSION"
    Set sc = service.ProcessInput(hard, .hardDecision)
    If $System.Status.IsError(sc) { Write "FAIL temperature event: ",$System.Status.GetErrorText(sc),! Quit 1 }
    If '$IsObject(hardDecision) { Write "FAIL missing temperature response",! Quit 1 }
    If hardDecision.Route '= "REVIEW" { Write "FAIL temperature route",! Set failures = failures + 1 }
    If hardDecision.Source '= "policy" { Write "FAIL temperature source",! Set failures = failures + 1 }

    Set bad = ##class(RouteGuard.Test.Policy).Example()
    Set bad.EventId = "evt-invalid-"_$SYSTEM.Util.CreateGUID()
    Set bad.ShipmentId = ""
    Set sc = service.ProcessInput(bad, .badDecision)
    If $System.Status.IsError(sc) { Write "FAIL invalid request response: ",$System.Status.GetErrorText(sc),! Quit 1 }
    If '$IsObject(badDecision) { Write "FAIL missing invalid request response",! Quit 1 }
    If badDecision.Source '= "validation" { Write "FAIL invalid request source",! Set failures = failures + 1 }
    If ##class(RouteGuard.Audit).%ExistsId(bad.EventId) { Write "FAIL invalid request audit",! Set failures = failures + 1 }

    Write "PRODUCTION_TEST_FAILURES=",failures,!
    Quit failures
}

}
