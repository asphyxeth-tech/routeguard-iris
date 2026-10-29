/// Stores one recommendation per event ID; no external shipment system is changed.
Class RouteGuard.Operation.Record Extends Ens.BusinessOperation
{

Parameter ADAPTER = "Ens.OutboundAdapter";
Parameter INVOCATION = "Queue";

Method SaveDecision(pRequest As RouteGuard.Message.Decision, Output pResponse As RouteGuard.Message.Decision) As %Status
{
    Set pResponse = ##class(RouteGuard.Message.Decision).%New()
    Set prior = ##class(RouteGuard.Audit).%OpenId(pRequest.EventId)
    If $IsObject(prior) {
        Set pResponse.EventId = prior.EventId
        Set pResponse.ShipmentId = prior.ShipmentId
        Set pResponse.EventType = prior.EventType
        Set pResponse.Route = prior.Route
        Set pResponse.Reason = prior.Reason
        Set pResponse.Source = prior.Source
        Set pResponse.Replay = 1
        Quit $$$OK
    }

    Set audit = ##class(RouteGuard.Audit).%New()
    Set audit.EventId = pRequest.EventId
    Set audit.ShipmentId = pRequest.ShipmentId
    Set audit.EventType = pRequest.EventType
    Set audit.Route = pRequest.Route
    Set audit.Reason = pRequest.Reason
    Set audit.Source = pRequest.Source
    Set audit.CreatedAt = $ZDateTime($H,3)
    Set sc = audit.%Save()
    If $System.Status.IsError(sc) Quit sc
    Set pResponse.EventId = audit.EventId
    Set pResponse.ShipmentId = audit.ShipmentId
    Set pResponse.EventType = audit.EventType
    Set pResponse.Route = audit.Route
    Set pResponse.Reason = audit.Reason
    Set pResponse.Source = audit.Source
    Set pResponse.Replay = 0
    Quit $$$OK
}

XData MessageMap
{
<MapItems>
  <MapItem MessageType="RouteGuard.Message.Decision">
    <Method>SaveDecision</Method>
  </MapItem>
</MapItems>
}

}
