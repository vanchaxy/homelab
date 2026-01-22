locals {
  argo = {
    chart = yamldecode(file("${path.module}/../../k8s/system/argocd/Chart.yaml"))
    values = yamldecode(file("${path.module}/../../k8s/system/argocd/values.yaml")).argo-cd
    redis-secret = file("${path.module}/../../k8s/system/argocd/templates/redis-secret.yaml")
  }
  ignore_fields = ["metadata.labels.\"argocd.argoproj.io/instance\""]
}

data "helm_template" "argocd-template" {
  name       = "argocd"
  repository = local.argo.chart.dependencies[0].repository
  chart      = local.argo.chart.dependencies[0].name
  version    = local.argo.chart.dependencies[0].version

  values = [
    yamlencode(local.argo.values)
  ]

  set {
    name  = "configs.secret.createSecret"
    value = true
  }

  namespace    = "argocd"
  kube_version = "v1.30.0"
}

resource "kubectl_manifest" "argocd-ns" {
  yaml_body = <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: argocd
YAML
}

resource "kubectl_manifest" "argocd-redis-secret" {
  ignore_fields = local.ignore_fields
  yaml_body     = local.argo.redis-secret

  depends_on = [kubectl_manifest.argocd-ns]
}

resource "kubectl_manifest" "argocd-apply" {
  for_each = data.helm_template.argocd-template.manifests

  ignore_fields = local.ignore_fields
  yaml_body     = each.value

  depends_on = [kubectl_manifest.argocd-ns, kubectl_manifest.argocd-redis-secret]
}

resource "null_resource" "wait_for_crd" {
  provisioner "local-exec" {
    command = "kubectl -n argocd wait --timeout=60s --for condition=Established crd/applications.argoproj.io crd/applicationsets.argoproj.io"
  }

  depends_on = [kubectl_manifest.argocd-apply]
}

resource "kubectl_manifest" "disable-sync" {
  ignore_fields = local.ignore_fields
  yaml_body     = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: system
  namespace: argocd
spec:
  clusterResourceWhitelist:
  - group: '*'
    kind: '*'
  destinations:
  - namespace: '*'
    server: '*'
  sourceRepos:
  - '*'
  syncWindows:
  - applications: ['*']
    duration: 1h
    kind: deny
    manualSync: true
    schedule: '* * * * *'
    timeZone: UTC
YAML

  depends_on = [null_resource.wait_for_crd]
}

resource "kubectl_manifest" "argocd-app" {
  ignore_fields = local.ignore_fields
  yaml_body     = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: argocd
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/vanchaxy/homelab-new
    path: k8s/system/argocd
    targetRevision: main
  destination:
    name: in-cluster
    namespace: argocd
YAML

  depends_on = [kubectl_manifest.disable-sync]
}
