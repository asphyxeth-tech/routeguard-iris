/// One durable, idempotent decision record per synthetic carrier event.
Class RouteGuard.Audit Extends %Persistent
{

Property EventId As %String(MAXLEN = 80) [ Required ];
Property ShipmentId As %String(MAXLEN = 80);
Property EventType As %String(MAXLEN = 32);
Property Route As %String(MAXLEN = 16);
Property Reason As %String(MAXLEN = 500);
Property Source As %String(MAXLEN = 24);
Property CreatedAt As %TimeStamp;

Index EventKey On EventId [ IdKey, Unique ];

}
