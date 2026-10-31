/// Calls AI Hub once for a bounded recommendation; core policy validates it later.
Class RouteGuard.AI.Decider Extends %RegisteredObject
{

ClassMethod Decide(event As RouteGuard.Message.Exception, Output route As %String, Output reason As %String) As %Status
{
    Set route = "", reason = ""
    Set sc = ##class(RouteGuard.Policy).Validate(event)
    If $System.Status.IsError(sc) Quit sc
    Set request = {
        "eventType": (event.EventType),
        "delayMinutes": (event.DelayMinutes),
        "alternateAvailable": (event.AlternateAvailable),
        "carrierNote": (event.CarrierNote)
    }

    Try {
        Set agent = ##class(RouteGuard.AI.Agent).%New()
        Set sc = agent.%Init()
        If $System.Status.IsOK(sc) {
            Set session = agent.CreateSession({"max_tokens":200,"max_iterations":1})
            Set response = agent.Chat(session,request.%ToJSON())
            If '$IsObject(response) {
                Set sc = $$$ERROR($$$GeneralError,"AI Hub returned no response")
            } Else {
                Set sc = ##class(RouteGuard.AI.ResponseParser).Parse(response.Content,.route,.reason)
            }
        }
    } Catch ex {
        Set sc = ex.AsStatus()
    }
    Quit sc
}

}
