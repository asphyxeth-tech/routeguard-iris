/// Test double only: deterministic synthetic routes, never an AI Hub call.
Class RouteGuard.AI.Decider Extends %RegisteredObject
{

ClassMethod Decide(event As RouteGuard.Message.Exception, Output route As %String, Output reason As %String) As %Status
{
    Set ^RouteGuardTest("AICalls") = $Get(^RouteGuardTest("AICalls")) + 1
    Set route = "REVIEW", reason = "Synthetic test review."
    If event.CarrierNote = "STUB:CONTACT" {
        Set route = "CONTACT", reason = "Synthetic carrier update."
    } ElseIf event.CarrierNote = "STUB:EXPEDITE" {
        Set route = "EXPEDITE", reason = "Synthetic alternate route."
    } ElseIf event.CarrierNote = "STUB:DROP" {
        Set route = "DROP", reason = "Synthetic invalid model route."
    } ElseIf event.CarrierNote = "STUB:ERROR" {
        Quit $$$ERROR($$$GeneralError,"Synthetic agent failure")
    }
    Quit $$$OK
}

}
