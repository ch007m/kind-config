## Waypoint gRPC & HTTP server

To install the Waypoint gRPC & HTTP server on a kind kubernetes cluster, it is needed to avoid having to forward the grpc and HTTP 
traffic using the command `kubectl port-forward --address 0.0.0.0 service/waypoint 32000:9701` to create ingress resources

To install the different kubernetes resources composing the waypoint server, execute the following command
```bash
kubectl apply -f waypoint/
```
