#!/usr/local/bin/bash

# Bash 4 is needed !!

set -o errexit

CLUSTER_NAME=${1:-devcluster}
K8S_VERSION=${2:-1.19}
TO_BE_DELETED=${3:-true}
REG_NAME='kind-registry'

declare -A k8sVersions=(
  [1.19]='kindest/node:v1.19.1@sha256:98cf5288864662e37115e362b23e4369c8c4a408f99cbc06e58ac30ddc721600'
  [1.18]='kindest/node:v1.18.8@sha256:f4bcc97a0ad6e7abaf3f643d890add7efe6ee4ab90baeb374b4f41a4c95567eb'
  [1.17]='kindest/node:v1.17.11@sha256:5240a7a2c34bf241afb54ac05669f8a46661912eab05705d660971eeb12f6555'
  [1.16]='kindest/node:v1.16.15@sha256:a89c771f7de234e6547d43695c7ab047809ffc71a0c3b65aa54eda051c45ed20'
  [1.15]='kindest/node:v1.15.12@sha256:d9b939055c1e852fe3d86955ee24976cab46cba518abcb8b13ba70917e6547a6'
  [1.14]='kindest/node:v1.14.10@sha256:ce4355398a704fca68006f8a29f37aafb49f8fc2f64ede3ccd0d9198da910146'
  [1.13]='kindest/node:v1.13.12@sha256:1c1a48c2bfcbae4d5f4fa4310b5ed10756facad0b7a2ca93c7a4b5bae5db29f5'
)

# Delete cluster
if [ "$TO_BE_DELETED" = true ] ; then
    kind delete clusters ${CLUSTER_NAME}
fi

# Find, stop and remove any registry previously installed
matchingStarted=$(docker ps --filter="name=$reg_name" -q | xargs)
[[ -n $matchingStarted ]] && docker stop $matchingStarted

matching=$(docker ps -a --filter="name=$reg_name" -q | xargs)
[[ -n $matching ]] && docker rm $matching

# Create registry container unless it already exists
REG_PORT='5000'
running="$(docker inspect -f '{{.State.Running}}' "${REG_NAME}" 2>/dev/null || true)"
if [ "${running}" != 'true' ]; then
  docker run \
    -d --restart=always -p "${REG_PORT}:5000" --name "${REG_NAME}" \
    registry:2
fi

# create a cluster with the local registry enabled in containerd
cat <<EOF | kind create cluster --name="${CLUSTER_NAME}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  image: "${k8sVersions[$K8S_VERSION]}"
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
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${REG_PORT}"]
    endpoint = ["http://${REG_NAME}:${REG_PORT}"]
EOF

# connect the registry to the cluster network
docker network connect "kind" "${REG_NAME}"

# tell https://tilt.dev to use the registry
# https://docs.tilt.dev/choosing_clusters.html#discovering-the-registry
for node in $(kind get nodes); do
  kubectl annotate node "${node}" "kind.x-k8s.io/registry=localhost:${REG_PORT}";
done

sleep 5s

# Install the ingress-nginx controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml