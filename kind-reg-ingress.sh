#!/bin/sh
set -o errexit

TO_BE_DELETED=${1:-false}
CLUSTER_NAME=${2:-devcluster}
REG_NAME='kind-registry'

# Delete clusterif requested
if [ "$TO_BE_DELETED" = true ] ; then
    kind delete clusters ${CLUSTER_NAME}
fi

# Find, stop and remove any registry previously installed
matchingStarted=$(docker ps --filter="name=$reg_name" -q | xargs)
[[ -n $matchingStarted ]] && docker stop $matchingStarted

matching=$(docker ps -a --filter="name=$reg_name" -q | xargs)
[[ -n $matching ]] && docker rm $matching

# Create registry container unless it already exists
reg_port='5000'
running="$(docker inspect -f '{{.State.Running}}' "${REG_NAME}" 2>/dev/null || true)"
if [ "${running}" != 'true' ]; then
  docker run \
    -d --restart=always -p "${reg_port}:5000" --name "${REG_NAME}" \
    registry:2
fi

# create a cluster with the local registry enabled in containerd
cat <<EOF | kind create cluster --name="${CLUSTER_NAME}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${reg_port}"]
    endpoint = ["http://${REG_NAME}:${reg_port}"]
EOF

# connect the registry to the cluster network
docker network connect "kind" "${REG_NAME}"

# tell https://tilt.dev to use the registry
# https://docs.tilt.dev/choosing_clusters.html#discovering-the-registry
for node in $(kind get nodes); do
  kubectl annotate node "${node}" "kind.x-k8s.io/registry=localhost:${reg_port}";
done

sleep 5s

# Install the ingress-nginx controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml