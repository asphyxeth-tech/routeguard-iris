/// Synthetic shipment exception entering the RouteGuard production.
Class RouteGuard.Message.Exception Extends Ens.Request
{

Property EventId As %String(MAXLEN = 80);
Property ShipmentId As %String(MAXLEN = 80);
Property EventType As %String(MAXLEN = 32);
Property DelayMinutes As %Integer;
Property CarrierNote As %String(MAXLEN = 500);
Property AlternateAvailable As %Boolean;

}
