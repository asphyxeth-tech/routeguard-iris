/// Entry host for synthetic exception messages sent to the production.
Class RouteGuard.Service.Intake Extends Ens.BusinessService
{

Parameter ADAPTER = "";

Method OnProcessInput(pRequest As RouteGuard.Message.Exception, Output pResponse As RouteGuard.Message.Decision) As %Status
{
    Quit ..SendRequestSync("RouteGuard.Process.Triage",pRequest,.pResponse)
}

}
