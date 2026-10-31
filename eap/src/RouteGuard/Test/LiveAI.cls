/// One bounded, paid-provider smoke test on synthetic data. Run only with approval.
Class RouteGuard.Test.LiveAI Extends %RegisteredObject
{

ClassMethod Run() As %Integer
{
    If $System.Util.GetEnviron("OPENAI_API_KEY") = "" {
        Write "AI_LIVE_TEST_FAILURES=1 missing OPENAI_API_KEY",!
        Quit 1
    }
    Set sc = ##class(Ens.Director).GetProductionStatus(.productionName,.productionState)
    If $System.Status.IsError(sc) { Write "FAIL production status",! Quit 1 }
    If (productionState = 1),(productionName '= "RouteGuard.Production") { Write "FAIL another production is running",! Quit 1 }
    If (productionState '= 1) {
        Set sc = ##class(Ens.Director).StartProduction("RouteGuard.Production")
        If $System.Status.IsError(sc) { Write "FAIL start production",! Quit 1 }
    }
    Set sc = ##class(Ens.Director).CreateBusinessService("RouteGuard.Service.Intake",.service)
    If $System.Status.IsError(sc) { Write "FAIL create service",! Quit 1 }

    Set event = ##class(RouteGuard.Test.Policy).Example()
    Set event.EventId = "evt-live-ai-"_$System.Util.CreateGUID()
    Set event.CarrierNote = "Synthetic carrier event: loading bay closed, alternate route available."
    Set sc = service.ProcessInput(event,.decision)
    If $System.Status.IsError(sc) { Write "FAIL process event: ",$System.Status.GetErrorText(sc),! Quit 1 }
    If '$IsObject(decision) { Write "FAIL missing decision",! Quit 1 }
    Set failures = 0
    If decision.Source '= "ai" { Write "FAIL no live AI Hub decision; source=",decision.Source,! Set failures=failures+1 }
    If '$ListFind($ListBuild("CONTACT","EXPEDITE","REVIEW"),decision.Route) { Write "FAIL unsupported route",! Set failures=failures+1 }
    If decision.Reason = "" { Write "FAIL empty reason",! Set failures=failures+1 }
    Set audit = ##class(RouteGuard.Audit).%OpenId(event.EventId)
    If '$IsObject(audit) { Write "FAIL missing audit",! Set failures=failures+1 }
    If $IsObject(audit), audit.Source '= decision.Source { Write "FAIL audit source mismatch",! Set failures=failures+1 }
    Write "AI_LIVE_ROUTE=",decision.Route,!
    Write "AI_LIVE_SOURCE=",decision.Source,!
    Write "AI_LIVE_TEST_FAILURES=",failures,!
    Quit failures
}

}
