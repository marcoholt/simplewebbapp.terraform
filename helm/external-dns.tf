module "iam_external_dns" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.34"

  role_name = "${var.project}-externaldns-irsa"
  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = [aws_route53_zone.public.arn]

  oidc_providers = {
    main = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:external-dns"]
    }
  }
  tags = local.tags
}

resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  namespace  = "kube-system"

  values = [yamlencode({
    provider = "aws"
    policy   = "upsert-only"
    domainFilters = [var.domain_name]
    serviceAccount = {
      create = true
      name   = "external-dns"
      annotations = { "eks.amazonaws.com/role-arn" = module.iam_external_dns.iam_role_arn }
    }
  })]
}
