data "aws_route53_zone" "domain" {
  name         = var.domain_name
  private_zone = false
}

resource "kubernetes_namespace" "greencity" {
  for_each = toset(var.k8s_namespaces)

  metadata {
    name = each.key
  }
}

module "aws_load_balancer_controller_irsa_role" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role-for-service-accounts-eks?ref=de95e21a3bc51cd3a44b3b95a4c2f61000649ebb"   # commit hash for version 5.39.1
#   source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#   version = "5.39.1"

  role_name = "aws-load-balancer-controller"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

resource "helm_release" "aws_load_balancer_controller" {
  name = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.8.1"

  set {
    name  = "replicaCount"
    value = 1
  }

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.aws_load_balancer_controller_irsa_role.iam_role_arn
  }
}

module "aws_external_dns_irsa_role" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role-for-service-accounts-eks?ref=de95e21a3bc51cd3a44b3b95a4c2f61000649ebb"   # commit hash for version 5.39.1
#   source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#   version = "5.39.1"

  role_name                     = "external-dns"
  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = ["arn:aws:route53:::hostedzone/${data.aws_route53_zone.domain.zone_id}"]

  oidc_providers = {
    ex = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["kube-system:external-dns"]
    }
  }

}

resource "helm_release" "external-dns" {
  name       = "external-dns"
  namespace  = "kube-system"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "external-dns"
  version    = "7.5.7"

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.aws_external_dns_irsa_role.iam_role_arn
  }

  set {
    name  = "serviceAccount.name"
    value = "external-dns"
  }

  set {
    name  = "zoneType"
    value = "public"
  }

  set {
    name  = "policy"
    value = "sync"
  }

  set {
    name  = "domainFilters[0]"
    value = var.domain_name
  }

  set {
    name  = "provider"
    value = "aws"
  }

  set {
    name  = "txtOwnerId"
    value = "external-dns"
  }

  depends_on = [ helm_release.aws_load_balancer_controller ]
}



module "external_secrets_irsa_role" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role-for-service-accounts-eks?ref=de95e21a3bc51cd3a44b3b95a4c2f61000649ebb"   # commit hash for version 5.39.1
#   source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#   version = "5.39.1"

  role_name                           = "external-secrets"
  attach_external_secrets_policy      = true
  external_secrets_ssm_parameter_arns = var.parameter_arns
  external_secrets_kms_key_arns                      = var.kms_key_arns
  external_secrets_secrets_manager_create_permission = false

  oidc_providers = {
    ex = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = [
        "greencity:external-secrets-account",
        "argocd:external-secrets-account"
      ]
    }
  }
}

resource "helm_release" "external_secret_operator" {
  name = "external-secrets-greencity"
  repository = "https://charts.external-secrets.io"
  chart = "external-secrets"
  version = "0.9.19"

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.external_secrets_irsa_role.iam_role_arn
  }

  set {
    name  = "serviceAccount.name"
    value = "external-secrets-account"
  }

  depends_on = [ helm_release.aws_load_balancer_controller ]

}

resource "helm_release" "datadog_agent" {
  name       = "datadog-agent"
  chart      = "datadog"
  repository = "https://helm.datadoghq.com"
  version    = "3.66.0"
  namespace  = "greencity"

  set_sensitive {
    name  = "datadog.apiKey"
    value = var.datadog_api_key
  }

  set {
    name  = "datadog.site"
    value = var.datadog_site
  }

  set {
    name  = "datadog.logs.enabled"
    value = true
  }

  set {
    name  = "datadog.logs.containerCollectAll"
    value = true
  }

  set {
    name  = "datadog.leaderElection"
    value = true
  }

  set {
    name  = "datadog.collectEvents"
    value = true
  }

  set {
    name  = "clusterAgent.enabled"
    value = true
  }

  set {
    name  = "clusterAgent.metricsProvider.enabled"
    value = true
  }

  set {
    name  = "networkMonitoring.enabled"
    value = true
  }

  set {
    name  = "systemProbe.enableTCPQueueLength"
    value = true
  }

  set {
    name  = "systemProbe.enableOOMKill"
    value = true
  }

  set {
    name  = "securityAgent.runtime.enabled"
    value = true
  }

  set {
    name  = "datadog.hostVolumeMountPropagation"
    value = "HostToContainer"
  }

  depends_on = [ helm_release.aws_load_balancer_controller, kubernetes_namespace.greencity["greencity"] ]
}

resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "monitoring"
  version    = "60.3.0"

  set_sensitive {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }

  set_sensitive {
    name  = "grafana.adminUser"
    value = var.grafana_admin_user
  }

  depends_on = [ helm_release.aws_load_balancer_controller, kubernetes_namespace.greencity["monitoring"] ]
}

resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"
  version    = "2.10.2"
  namespace  = "monitoring"

  depends_on = [ helm_release.aws_load_balancer_controller, kubernetes_namespace.greencity["monitoring"] ]
}

resource "helm_release" "kubernetes_dashboard" {

  name = "kubernetes-dashboard"

  repository = "https://kubernetes.github.io/dashboard/"
  chart      = "kubernetes-dashboard"
  namespace  = "kube-dashboard"
  version    = "7.5.0"
 
  set {
    name  = "metricsScraper.enabled"
    value = "true"
  }

  depends_on = [ helm_release.aws_load_balancer_controller, kubernetes_namespace.greencity["kube-dashboard"] ]
}

resource "kubernetes_cluster_role_binding" "kube-dashboard-view" {
  metadata {
    name      = "kube-dashboard-view"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "view"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = "kube-dashboard"
  }

  depends_on = [ helm_release.kubernetes_dashboard ]
}

resource "helm_release" "sonarqube" {
  name       = "sonarqube"
  repository = "https://SonarSource.github.io/helm-chart-sonarqube"
  chart      = "sonarqube"
  version    = "10.6.0"
  namespace  = "sonarqube"

  timeout = "600"

  set {
    name = "postgresql.enabled"
    value = "false"
  }

  set {
    name = "jdbcOverwrite.enable"
    value = "true"
  }

  set_sensitive {
    name = "jdbcOverwrite.jdbcUrl"
    value = join("", ["jdbc:postgresql://", var.sonarqube_db_instance_address, ":5432/", var.sonarqube_database_name])
  }

  set_sensitive {
    name = "jdbcOverwrite.jdbcUsername"
    value = var.sonarqube_database_username
  }

  set_sensitive {
    name = "jdbcOverwrite.jdbcPassword"
    value = var.sonarqube_database_password
  }

  set_sensitive {
    name = "account.currentAdminPassword"
    value = var.sonarqube_current_admin_password
  }

  set_sensitive {
    name = "account.adminPassword"
    value = var.sonarqube_admin_password
  }

#   set {
#     name = "ingress.enabled"
#     value = "true"
#   }

#   set {
#     name = "ingress.hosts[0].name"
#     value = var.sonarqube_domain_name
#   }

#   set {
#     name = "ingress.hosts[0].path"
#     value = "/"
#   }

#   set {
#     name = "ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/proxy-body-size"
#     value = "64m"
#   }

#   set {
#     name = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/load-balancer-name"
#     value = "sonarqube-ingress-alb"
#   }

#   set {
#     name = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/target-type"
#     value = "ip"
#   }

#   set {
#     name = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/schema"
#     value = "internet-facing"
#   }

#   set {
#     name = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/backend-protocol"
#     value = "HTTP"
#   }

#   set {
#     name = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/listen-ports"
#     value = "[{\"HTTPS\":443}]"
#   }

#   set {
#     name = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/certificate-arn"
#     value = var.sonarqube_ssl_certificate_arn
#   }

#   set {
#     name = "ingress.annotations.external-dns\\.alpha\\.kubernetes\\.io/hostname"
#     value = var.sonarqube_domain_name
#   }

#   set {
#     name = "jvmOpts"
#     value = "-Xmx1024m -Xms1024m -XX:+HeapDumpOnOutOfMemoryError"
#   }

#   set {
#     name = "jvmCeOpts"
#     value = "-Xmx1024m -Xms1024m -XX:+HeapDumpOnOutOfMemoryError"
#   }

#   values = [
#     file("${path.module}/sonarqube/values.yaml")
#   ]

  depends_on = [ helm_release.aws_load_balancer_controller, kubernetes_namespace.greencity["sonarqube"] ]
}

resource "helm_release" "argocd" {

  name = "argocd"

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"
  version    = "7.3.3"

#   create_namespace = true

  depends_on = [ helm_release.aws_load_balancer_controller, kubernetes_namespace.greencity["argocd"] ]
}
