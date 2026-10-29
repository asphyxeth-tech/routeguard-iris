/// Synthetic shipment-exception pipeline; no outbound physical-world action.
Class RouteGuard.Production Extends Ens.Production
{

XData ProductionDefinition
{
<Production Name="RouteGuard.Production" LogGeneralTraceEvents="true">
  <ActorPoolSize>2</ActorPoolSize>
  <Item Name="RouteGuard.Service.Intake" ClassName="RouteGuard.Service.Intake" PoolSize="1" Enabled="true" Foreground="false" />
  <Item Name="RouteGuard.Process.Triage" ClassName="RouteGuard.Process.Triage" PoolSize="1" Enabled="true" Foreground="false" />
  <Item Name="RouteGuard.Operation.Record" ClassName="RouteGuard.Operation.Record" PoolSize="1" Enabled="true" Foreground="false" />
</Production>
}

}
