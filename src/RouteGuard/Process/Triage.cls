/// Validates and routes exceptions, with an explicit safe fallback before AI Hub is installed.
Class RouteGuard.Process.Triage Extends Ens.BusinessProcess [ ClassType = persistent ]
{

Method OnRequest(pRequest As RouteGuard.Message.Exception, Output pResponse As RouteGuard.Message.Decision) As %Status
{
    Set pResponse = ##class(RouteGuard.Message.Decision).%New()
    Set pResponse.EventId = pRequest.EventId
    Set pResponse.ShipmentId = pRequest.ShipmentId
    Set pResponse.EventType = pRequest.EventType
    Set pResponse.Replay = 0

    Set sc = ##class(RouteGuard.Policy).Validate(pRequest)
    If $System.Status.IsError(sc) {
        Set pResponse.Route = "REVIEW"
        Set pResponse.Reason = $Extract($System.Status.GetErrorText(sc),1,500)
        Set pResponse.Source = "validation"
        Quit $$$OK
    }

    Set prior = ##class(RouteGuard.Audit).%OpenId(pRequest.EventId)
    If $IsObject(prior) {
        Set pResponse.Route = prior.Route
        Set pResponse.Reason = prior.Reason
        Set pResponse.Source = prior.Source
        Set pResponse.Replay = 1
        Quit $$$OK
    }

    Set sc = ##class(RouteGuard.Policy).HardRoute(pRequest,.route,.reason)
    If $System.Status.IsError(sc) Quit sc
    If (route '= "") {
        Set source = "policy"
    } Else {
        Set route = "REVIEW"
        Set reason = "AI Hub agent is unavailable in this environment."
        Set source = "fallback"
        If ##class(%Dictionary.ClassDefinition).%ExistsId("RouteGuard.AI.Decider") {
            Try {
                Set aiSC = $ClassMethod("RouteGuard.AI.Decider","Decide",pRequest,.proposedRoute,.proposedReason)
                If $System.Status.IsOK(aiSC) {
                    Set normalizeSC = ##class(RouteGuard.Policy).NormalizeAgentChoice(pRequest,proposedRoute,proposedReason,.route,.reason)
                    If $System.Status.IsOK(normalizeSC) {
                        Set source = "ai"
                        Set normalizedProposal = $ZCONVERT($ZSTRIP(proposedRoute,"<>W"),"U")
                        If (route '= normalizedProposal)||($ZSTRIP(proposedReason,"<>W") = "") Set source = "guardrail"
                    } Else {
                        Set route = "REVIEW", reason = "AI Hub decision could not be validated; manual review required.", source = "fallback"
                    }
                } Else {
                    Set route = "REVIEW", reason = "AI Hub agent failed; manual review required.", source = "fallback"
                }
            } Catch ex {
                Set route = "REVIEW", reason = "AI Hub agent failed; manual review required.", source = "fallback"
            }
        }
    }

    Set pResponse.Route = route
    Set pResponse.Reason = reason
    Set pResponse.Source = source
    Set sc = ..SendRequestSync("RouteGuard.Operation.Record",pResponse,.recordResponse)
    Quit sc
}

Method OnResponse(pRequest As Ens.Request, pResponse As Ens.Response, pCallRequest As Ens.Request, pCallResponse As Ens.Response, pCompletionKey As %String) As %Status
{
    Quit $$$OK
}

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}
