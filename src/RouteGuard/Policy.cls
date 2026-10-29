/// Input and post-agent limits applied independently of model output.
Class RouteGuard.Policy Extends %RegisteredObject
{

ClassMethod Validate(event As RouteGuard.Message.Exception) As %Status
{
    If '$IsObject(event) Quit $$$ERROR($$$GeneralError, "Exception object is required")
    If ($ZSTRIP(event.EventId,"<>W") = "") Quit $$$ERROR($$$GeneralError, "EventId is required")
    If ($ZSTRIP(event.ShipmentId,"<>W") = "") Quit $$$ERROR($$$GeneralError, "ShipmentId is required")
    If ($Length(event.EventId) > 80) Quit $$$ERROR($$$GeneralError, "EventId is too long")
    If ($Length(event.ShipmentId) > 80) Quit $$$ERROR($$$GeneralError, "ShipmentId is too long")
    If '$ListFind($ListBuild("DELAY","ACCESS_BLOCKED","STATUS_STALE","TEMPERATURE_EXCURSION"),event.EventType) Quit $$$ERROR($$$GeneralError, "EventType is not supported")
    If (event.DelayMinutes < 0)!(event.DelayMinutes > 1440) Quit $$$ERROR($$$GeneralError, "DelayMinutes must be between 0 and 1440")
    If ($Length(event.CarrierNote) > 500) Quit $$$ERROR($$$GeneralError, "CarrierNote is too long")
    If (event.AlternateAvailable '= 0)&&(event.AlternateAvailable '= 1) Quit $$$ERROR($$$GeneralError, "AlternateAvailable must be 0 or 1")
    Quit $$$OK
}

ClassMethod HardRoute(event As RouteGuard.Message.Exception, Output route As %String, Output reason As %String) As %Status
{
    Set route = "", reason = ""
    If (event.EventType = "TEMPERATURE_EXCURSION") {
        Set route = "REVIEW", reason = "Temperature excursion requires human review."
    } ElseIf (event.DelayMinutes > 180) {
        Set route = "REVIEW", reason = "Delay exceeds the automated routing limit."
    }
    Quit $$$OK
}

ClassMethod NormalizeAgentChoice(event As RouteGuard.Message.Exception, proposedRoute As %String, proposedReason As %String, Output finalRoute As %String, Output finalReason As %String) As %Status
{
    Set finalRoute = $ZCONVERT($ZSTRIP(proposedRoute,"<>W"),"U")
    Set finalReason = $Extract($ZSTRIP(proposedReason,"<>W"),1,500)
    If '$ListFind($ListBuild("CONTACT","EXPEDITE","REVIEW"),finalRoute) {
        Set finalRoute = "REVIEW", finalReason = "Agent returned an unsupported route."
    }
    If (finalRoute = "EXPEDITE")&&('event.AlternateAvailable) {
        Set finalRoute = "REVIEW", finalReason = "No alternate route is available for expedited handling."
    }
    Do ..HardRoute(event,.hardRoute,.hardReason)
    If (hardRoute '= "") {
        Set finalRoute = hardRoute, finalReason = hardReason
    }
    If (finalReason = "") Set finalReason = "No agent reason was provided; review is required.", finalRoute = "REVIEW"
    Quit $$$OK
}

}
