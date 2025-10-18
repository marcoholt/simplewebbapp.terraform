resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "5.51.2"

  # For quick access in dev we expose via LoadBalancer.
  values = [yamlencode({
    server = { service = { type = "LoadBalancer" } }
  })]
}
