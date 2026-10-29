/// Bounded routing recommendation; no physical shipment action is taken.
Class RouteGuard.Message.Decision Extends Ens.Response
{

Property EventId As %String(MAXLEN = 80);
Property ShipmentId As %String(MAXLEN = 80);
Property EventType As %String(MAXLEN = 32);
Property Route As %String(MAXLEN = 16);
Property Reason As %String(MAXLEN = 500);
Property Source As %String(MAXLEN = 24);
Property Replay As %Boolean;

}
