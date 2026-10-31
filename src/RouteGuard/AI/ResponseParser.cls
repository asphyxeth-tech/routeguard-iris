/// Parses the AI Hub text response as a bounded JSON recommendation.
Class RouteGuard.AI.ResponseParser Extends %RegisteredObject
{

ClassMethod Parse(text As %String, Output route As %String, Output reason As %String) As %Status
{
    Set route = "", reason = "", parseFailed = 0
    If (text = "")!($Length(text) > 1024) Quit $$$ERROR($$$GeneralError,"Agent response must be 1 to 1024 characters")

    Try {
        Set parsed = {}.%FromJSON(text)
    } Catch ex {
        Set parseFailed = 1
    }
    If $Get(parseFailed) Quit $$$ERROR($$$GeneralError,"Agent response is not valid JSON")
    If '$IsObject(parsed) Quit $$$ERROR($$$GeneralError,"Agent response is not a JSON object")
    If 'parsed.%IsA("%DynamicObject") Quit $$$ERROR($$$GeneralError,"Agent response must be a JSON object")
    If parsed.%GetTypeOf("route") '= "string" Quit $$$ERROR($$$GeneralError,"Agent route must be text")
    If parsed.%GetTypeOf("reason") '= "string" Quit $$$ERROR($$$GeneralError,"Agent reason must be text")

    Set route = parsed.%Get("route"), reason = parsed.%Get("reason")
    If (route = "")!($Length(route) > 32) Quit $$$ERROR($$$GeneralError,"Agent route length is invalid")
    If $Length(reason) > 500 Quit $$$ERROR($$$GeneralError,"Agent reason is too long")
    Quit $$$OK
}

}
