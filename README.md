# Kubernetes kind configuration 

This project explains and contains instructions to set up a K8s cluster using `kind` 
and next to provision it with a docker registry, dashboard, ingress controller, ...

### Prerequisites

- [Docker client](https://docs.docker.com/desktop/)
- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/)
- [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [Terminal based UI to manage clusters - K9s](https://k9scli.io/) - optional but recommended !!

### Create the Kind cluster

Execute the following bash script to create a Kind cluster having a docker registry and ingress controller
```bash
./kind-reg-ingress.sh <NAME_OF_CLUSTER> <K8S_VERSION>
```
**<K8S_VERSION>**: Select one of the following values `1.13 to 1.19`. Default: `1.19`

### Deploy the OKD console

Create the `dashboard` namespace
```bash
kubectl create ns dashboard
```
Next deploy the K8s resources
```bash
kubectl apply -f https://raw.githubusercontent.com/ch007m/kind-config/master/okd-console/01-serviceaccount.yml
kubectl apply -f https://raw.githubusercontent.com/ch007m/kind-config/master/okd-console/02-rbac.yml
kubectl apply -f https://raw.githubusercontent.com/ch007m/kind-config/master/okd-console/03-deployment.yml
kubectl apply -f https://raw.githubusercontent.com/ch007m/kind-config/master/okd-console/04-svc.yml
kubectl apply -f https://raw.githubusercontent.com/ch007m/kind-config/master/okd-console/05-ingress.yml
```
Wait a few moments and next open the console within your browser `http://console.127.0.0.1.nip.io/` 

### Install OLM

Execute the following command to deploy the Operators Lifecycle Managers
```bash
kubectl create -f https://raw.githubusercontent.com/operator-framework/operator-lifecycle-manager/master/deploy/upstream/quickstart/crds.yaml
kubectl create -f https://raw.githubusercontent.com/operator-framework/operator-lifecycle-manager/master/deploy/upstream/quickstart/olm.yaml
```


