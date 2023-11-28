#!/bin/sh

VALUES="values.yaml"

helm template \
    --include-crds \
    --namespace argocd \
    --values "${VALUES}" \
    --set stopSync=${HOMELAB_STOP_SYNC:-false} \
    argocd . \
    | kubectl apply -n argocd -f -
