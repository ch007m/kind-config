#!/usr/bin/env bash

# /usr/local/Cellar/openssl@1.1/1.1.1h/bin/openssl \
#    req -x509 -sha256 -nodes -days 365 \
#    -newkey rsa:2048 \
#    -keyout tls.key \
#    -out tls.crt \
#    -subj "/CN=fortune-teller/O=fortune-teller" \
#    -addext "subjectAltName=DNS:fortune-teller.127.0.0.1.nip.io"
#
# kc delete secret/fortune-teller -n default
# kc create secret tls fortune-teller --key tls.key --cert tls.crt -n default
# kc delete ingress/waypoint-grpc -n default
# kc apply -f - <<EOF
#apiVersion: networking.k8s.io/v1beta1
#kind: Ingress
#metadata:
#  annotations:
#    kubernetes.io/ingress.class: "nginx"
#    nginx.ingress.kubernetes.io/ssl-redirect: "true"
#    nginx.ingress.kubernetes.io/backend-protocol: "GRPC"
#  name: fortune-ingress
#  namespace: default
#spec:
#  rules:
#  - host: fortune-teller.127.0.0.1.nip.io
#    http:
#      paths:
#      - backend:
#          serviceName: fortune-teller-service
#          servicePort: grpc
#  tls:
#  - secretName: fortune-teller
#    hosts:
#EOF
#
# kc get ingress -n default
#NAME              CLASS    HOSTS                             ADDRESS     PORTS     AGE
#fortune-ingress   <none>   fortune-teller.127.0.0.1.nip.io   localhost   80, 443   20m
#waypoint          <none>   waypoint-ui.127.0.0.1.nip.io      localhost   80        54m
#
# grpcurl -insecure fortune-teller.127.0.0.1.nip.io:443 build.stack.fortune.FortuneTeller/Predict
#
read -p "Service name : " SERVICE_NAME
read -p "Service port : " SERVICE_PORT
read -p "Ingress name : " INGRESS_NAME
read -p "Host name : " HOSTNAME
read -p "Namespace : " NAMESPACE
read -p "Suffix of the domain name : " suffix_domain
SUFFIX_DOMAIN=${suffix_domain:-127.0.0.1.nip.io}
NAMESPACE=${namespace:-default}

/usr/local/Cellar/openssl@1.1/1.1.1h/bin/openssl \
   req -x509 -sha256 -nodes -days 365 \
   -newkey rsa:2048 \
   -keyout tls.key \
   -out tls.crt \
   -subj "/CN=waypoint/O=waypoint" \
   -addext "subjectAltName=DNS:$HOSTNAME.$SUFFIX_DOMAIN"

kubectl delete secret/fortune-teller -n default
kubectl create secret tls $INGRESS_NAME --key tls.key --cert tls.crt -n default

cat >k8s-resources/$HOSTNAME-ingress.yml <<EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    #nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "GRPC"
    kubernetes.io/ingress.class: nginx
  labels:
    app: $INGRESS_NAME
  name: $INGRESS_NAME
  namespace: $NAMESPACE
spec:
  tls:
  - hosts:
    - $HOSTNAME.$SUFFIX_DOMAIN
    secretName: $INGRESS_NAME
  rules:
  - host: $HOSTNAME.$SUFFIX_DOMAIN
    http:
      paths:
      - backend:
          serviceName: $SERVICE_NAME
          servicePort: $SERVICE_PORT
        path: /
EOF

kubectl apply -f waypoint-grpc-ingress.yml

echo "URL to access the ingress service is : $HOSTNAME.$SUFFIX_DOMAIN"
echo "grpc request : grpcurl -insecure $HOSTNAME.$SUFFIX_DOMAIN:443 build.stack.fortune.FortuneTeller/Predict"