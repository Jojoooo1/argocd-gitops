#!/bin/bash
set -e

if [[ ! -x "$(command -v kubectl)" ]]; then
  echo "kubectl not found"
  exit 1
fi

if [[ ! -x "$(command -v kustomize)" ]]; then
  echo "kustomize not found"
  exit 1
fi

# Setup minikube
minikube delete
minikube start --cpus 4 --memory 8096
minikube addons enable ingress

echo
echo ">>> Waiting for ingress to start"
kubectl -n kube-system rollout status deployment/nginx-ingress-controller
echo ">>> ingress deployment is done"

echo
echo ">>> Deploying argocd"
kustomize build ../../../base/argocd | kubectl apply -f -

echo
echo ">>> Waiting for argocd to start"
kubectl -n argocd rollout status deployment/argocd-server
echo ">>> argocd deployment is done"

echo
echo ">>> Deploying argocd parent applications" # declarative-setup: App of Apps (https://argoproj.github.io/argo-cd/operator-manual/declarative-setup/)
kubectl apply -f ../_argocd-parent-app
echo ">>> argocd Applications & projects deployments are done"

kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2 # Get password
kubectl port-forward svc/argocd-server -n argocd 8080:443

# kubectl -n default port-forward deployment/spring-app-backend-service 8080:8080
# kubectl -n default port-forward service/spring-app-database-service 3306:3306
