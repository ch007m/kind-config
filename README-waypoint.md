## Waypoint gRPC & HTTP server

To install the Waypoint gRPC & HTTP server on a kind kubernetes cluster, it is needed to avoid having to forward the grpc and HTTP 
traffic using the command `kubectl port-forward --address 0.0.0.0 service/waypoint 32000:9701` to create ingress resources

To install the different kubernetes resources composing the waypoint server, execute the following command
```bash
kubectl create ns waypoint
kubectl apply -f waypoint/
```

Generate first a TOKEN using the command `waypoint token new` to be authenticqted with the UI or gRPC server
```bash
TOKEN=$(waypoint token new)
```

Next you can test if your server is accessible using the HTTP or gRPC endpoints 
```bash
curl -k -H "Authorization: $TOKEN"  https://waypoint-ui.127.0.0.1.nip.io
```
and 

```bash
grpcurl -insecure -H "client-api-protocol: 1,1" -H "Authorization: $TOKEN" waypoint-grpc.127.0.0.1.nip.io:443 describe hashicorp.waypoint.Waypoint 
hashicorp.waypoint.Waypoint is a service:
service Waypoint {
  rpc BootstrapToken ( .google.protobuf.Empty ) returns ( .hashicorp.waypoint.NewTokenResponse );
  rpc CancelJob ( .hashicorp.waypoint.CancelJobRequest ) returns ( .google.protobuf.Empty );
  rpc ConvertInviteToken ( .hashicorp.waypoint.ConvertInviteTokenRequest ) returns ( .hashicorp.waypoint.NewTokenResponse );
  rpc CreateHostname ( .hashicorp.waypoint.CreateHostnameRequest ) returns ( .hashicorp.waypoint.CreateHostnameResponse );
  rpc DeleteHostname ( .hashicorp.waypoint.DeleteHostnameRequest ) returns ( .google.protobuf.Empty );
...
```

If that works you can try to register for your waypoint the context of the server
```bash
waypoint context create \
    -server-addr=waypoint-grpc.127.0.0.1.nip.io:443 \
    -server-auth-token=abcd1234 \
    -server-tls \
    -server-tls-skip-verify \
    -set-default my-k8s-server
```
and control if the context is correct
```bash
 waypoint context verify my-k8s-server
⠹ Connecting with context "my-k8s-server"...
✓ Context "my-k8s-server" connected successfully.
```
