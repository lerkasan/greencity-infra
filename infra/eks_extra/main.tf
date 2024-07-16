data "aws_route53_zone" "domain" {
  name         = var.domain_name
  private_zone = false
}

resource "kubernetes_namespace" "greencity" {
  for_each = toset(var.k8s_namespaces)

  metadata {
    name = each.key
  }

#   depends_on = [ module.eks ]
}

module "aws_load_balancer_controller_irsa_role" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role-for-service-accounts-eks?ref=de95e21a3bc51cd3a44b3b95a4c2f61000649ebb"   # commit hash for version 5.39.1
#   source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#   version = "5.39.1"

  role_name = "aws-load-balancer-controller"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = var.oidc_provider_arn # module.eks.oidc_provider_arn
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
    value = var.cluster_name # module.eks.cluster_name
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


# resource "helm_release" "ingress" {
#   name       = "ingress"
#   repository = "https://kubernetes.github.io/ingress-nginx"
#   chart      = "ingress-nginx"
#   version    = "4.10.1"
#   namespace  = "kube-system"

# #   depends_on = [ helm_release.aws_load_balancer_controller ]
# }

module "aws_external_dns_irsa_role" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role-for-service-accounts-eks?ref=de95e21a3bc51cd3a44b3b95a4c2f61000649ebb"   # commit hash for version 5.39.1
#   source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#   version = "5.39.1"

  role_name                     = "external-dns"
  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = ["arn:aws:route53:::hostedzone/${data.aws_route53_zone.domain.zone_id}"]

  oidc_providers = {
    ex = {
      provider_arn               = var.oidc_provider_arn # module.eks.oidc_provider_arn 
      namespace_service_accounts = ["kube-system:external-dns"]
    }
  }

}

resource "helm_release" "external-dns" {
  name       = "external-dns"
  namespace  = "kube-system"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "external-dns"
  version    = "7.5.7" # "7.5.5"

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
    name  = "txtOwnerId" #TXT record identifier
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
#   external_secrets_secrets_manager_arns              = []
#   external_secrets_secrets_manager_arns              = ["arn:aws:secretsmanager:*:*:secret:*"]
  external_secrets_kms_key_arns                      = var.kms_key_arns # [ aws_kms_key.ssm_param_encrypt_key.arn ]  
  external_secrets_secrets_manager_create_permission = false

  oidc_providers = {
    ex = {
      provider_arn               = var.oidc_provider_arn # module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "greencity:external-secrets-account",
        # "greencity:external-secrets-account-backcore",
        # "greencity:external-secrets-account-backuser",
        "argocd:external-secrets-account"
      ]
    #   namespace_service_accounts = ["default:external-secrets-account"]
    }
  }

#   depends_on = [ kubernetes_namespace.greencity ]
#   tags = local.tags
}

resource "helm_release" "external_secret_operator" {
# for_each = toset([ "greencity", "argocd" ])

  name = "external-secrets-greencity"
#   namespace  = each.key
#   namespace  = "greencity"
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

#   values = local.kube_prometheus_stack_values

  set_sensitive {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
    # value = random_password.grafana_admin_password.result
  }

  set_sensitive {
    name  = "grafana.adminUser"
    value = var.grafana_admin_user
  }

  depends_on = [ helm_release.aws_load_balancer_controller, kubernetes_namespace.greencity["monitoring"] ]
#   depends_on = [kubernetes_secret_v1.kube_prometheus_ingress_auth]
}

resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"
  version    = "2.10.2"
  namespace  = "monitoring"

#   values = [
#     file("${path.module}/../loki/values.yaml")
#   ]
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

  timeout = "360"

#   set {
#     name = "edition"
#     value = "developer"
#   }

#   set {
#     name = "service.type"
#     value = "LoadBalancer"
#   }

  set {
    name = "postgresql.enabled"
    value = "false"
  }

  set {
    name = "jdbcOverwrite.enable"
    value = "true"
  }

  set {
    name = "jdbcOverwrite.jdbcUrl"
    value = join("", ["jdbc:postgresql://", var.sonarqube_db_instance_address, ":5432/", var.sonarqube_database_name])
  }

  set {
    name = "jdbcOverwrite.jdbcUsername"
    value = var.sonarqube_database_username
  }

  set {
    name = "jdbcOverwrite.jdbcPassword"
    value = var.sonarqube_database_password
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
# 	# value = "[{\"HTTP\":9000}, {\"HTTPS\":443}]"
#   }

# #   set {
# #     name = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/ssl-redirect"
# #     value = "443"
# #   }

#   set {
#     name = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/certificate-arn"
#     value = var.sonarqube_ssl_certificate_arn
#   }

#   set {
#     name = "ingress.annotations.external-dns\\.alpha\\.kubernetes\\.io/hostname"
#     value = var.sonarqube_domain_name
#   }

        # "alb.ingress.kubernetes.io/load-balancer-name" = "argocd-ingress-alb"   +
        # "alb.ingress.kubernetes.io/target-type" = "ip" +
        # "alb.ingress.kubernetes.io/scheme" = "internet-facing" +
        # "alb.ingress.kubernetes.io/group.name" = "argocd-ingress-group"
        # "alb.ingress.kubernetes.io/backend-protocol" = "HTTPS"                  +
        # "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTPS\":443}]"   +
        # "alb.ingress.kubernetes.io/certificate-arn"= var.argocd_ui_ssl_cert_arn +
        # "external-dns.alpha.kubernetes.io/hostname" = var.argocd_ui_hostname +

#   ingress:
#     enabled: true
#     hosts:
#     - name: sonar.example.net
#       path: /*
#     annotations:
#       nginx.ingress.kubernetes.io/proxy-body-size: "64m" +
#       alb.ingress.kubernetes.io/load-balancer-name: "cicd-eks-alb-sonarqube" +
#       alb.ingress.kubernetes.io/backend-protocol: "HTTP" +
#       alb.ingress.kubernetes.io/scheme: "internal"
#       alb.ingress.kubernetes.io/ssl-redirect: "443" +
#       alb.ingress.kubernetes.io/target-type: 'ip' +
#       alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:ap-southeast-1:xxxx:certificate/xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx +

#   set {
#     name = "jvmOpts"
#     value = "-Xmx1024m -Xms1024m -XX:+HeapDumpOnOutOfMemoryError"
#   }

#   set {
#     name = "jvmCeOpts"
#     value = "-Xmx1024m -Xms1024m -XX:+HeapDumpOnOutOfMemoryError"
#   }

#   values = [
#     file("${path.module}/../loki/values.yaml")
#   ]
  depends_on = [ helm_release.aws_load_balancer_controller, kubernetes_namespace.greencity["sonarqube"] ]
}

# https://github.com/aws-ia/terraform-aws-eks-blueprints/issues/1307
# resource "null_resource" "clean_up_argocd_resources" {
#   triggers = {
#     eks_cluster_name = var.cluster_name
#   }
#   provisioner "local-exec" {
#     command     = <<-EOT
#       kubeconfig=/tmp/tf.clean_up_argocd.kubeconfig.yaml
#       aws eks update-kubeconfig --name ${self.triggers.eks_cluster_name} --kubeconfig $kubeconfig
#       rm -f /tmp/tf.clean_up_argocd_resources.err.log
#       kubectl --kubeconfig $kubeconfig get Application -A -o name | xargs -I {} kubectl --kubeconfig $kubeconfig -n argocd patch -p '{"metadata":{"finalizers":null}}' --type=merge {} 2> /tmp/tf.clean_up_argocd_resources.err.log || true
#       rm -f $kubeconfig
#     EOT
#     interpreter = ["bash", "-c"]
#     when        = destroy
#   }
# }

resource "helm_release" "argocd" {

  name = "argocd"

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"
  version    = "7.3.3"

#   create_namespace = true

#   set {
#     name  = "server.service.type"
#     value = "LoadBalancer"
#   }

#   set {
#     name  = "server.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
#     value = "nlb"
#   }
#   depends_on = [ module.custom_eks.eks_aws_auth ]
}


# resource "helm_release" "artifactory" {

#   name = "artifactory"

#   repository = "https://charts.jfrog.io"
#   chart      = "artifactory-oss"
#   namespace  = "artifactory-oss"
#   version    = "107.84.16"

#   create_namespace = true

#   set {
#     name  = "artifactory.postgresql.postgresqlPassword"
#     value = var.artifactory_database_password
#   }

#   set {
#     name  = "artifactory.nginx.enabled"
#     value = "false"
#   }

#   set {
#     name  = "artifactory.ingress.enabled"
#     value = "true"
#   }

#   set {
#     name  = "artifactory.ingress.hosts[0]"
#     value = var.artifactory_domain_name
#   }

#   set {
#     name  = "artifactory.ingress.tls[0].hosts[0]"
#     value = var.artifactory_domain_name
#   }

#   set {
#     name  = "artifactory.ingress.className"
#     value = "alb"
#   }

#   set {
#     name  = "artifactory.artifactory.service.type"
#     value = "NodePort"
#   }

#   set {
#     name = "artifactory.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/load-balancer-name"
#     value = "artifactory-ingress-alb"
#   }

#   set {
#     name = "artifactory.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/target-type"
#     value = "ip"
#   }

#   set {
#     name = "artifactory.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/scheme"
#     value = "internet-facing"
#   }

#   set {
#     name = "artifactory.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/backend-protocol"
#     value = "HTTP"
#   }

#   set {
#     name = "artifactory.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/listen-ports"
#     value = "[{\"HTTPS\":443}]"
# 	# value = "[{\"HTTP\":9000}, {\"HTTPS\":443}]"
#   }

# #   set {
# #     name = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/ssl-redirect"
# #     value = "443"
# #   }

#   set {
#     name = "artifactory.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/certificate-arn"
#     value = var.artifactory_ssl_certificate_arn
#   }

#   set {
#     name = "artifactory.ingress.annotations.external-dns\\.alpha\\.kubernetes\\.io/hostname"
#     value = var.artifactory_domain_name
#   }

#   depends_on = [ helm_release.aws_load_balancer_controller ]
# }






# artifactory:
#   admin:
#     ip: "<IP_RANGE>" # Example: "*" to allow access from anywhere
#     username: "admin"
#     password: "<PASSWD>"


# resource "kubernetes_manifest" "argocd_external_secrets_service_account" {

#   manifest = {
#     apiVersion = "v1"
#     kind       = "ServiceAccount"

#     metadata = {
#       name      = "external-secrets-account"
#       namespace = "argocd"
#       annotations = {
#         "eks.amazonaws.com/role-arn" = module.external_secrets_irsa_role.iam_role_arn
# 	  }
#     }
#   }

#   depends_on = [
#     helm_release.argocd
#   ]
# }



# resource "kubernetes_manifest" "external_cluster_secret_store" {

#   manifest = {
#     apiVersion = "external-secrets.io/v1beta1"
#     kind       = "ClusterSecretStore"

#     metadata = {
#       name      = "cluster-secretstore"
#     #   namespace = "default"
#     }

#     spec = {
#       provider = {
#         aws = {
#           service = "ParameterStore"
#           region = "us-east-1"           # TODO: add var.aws_region
#           auth = {
#             jwt = {
#               serviceAccountRef = {
#                 name = "external-secrets-account"
#               }
#             }
#           }
#         }
#       }
#     }
#   }

#   depends_on = [
#     helm_release.argocd,
#     helm_release.external_secret_operator,
#   ]
# }

# resource "kubernetes_manifest" "argocd_external_secret" {

#   manifest = {
#     apiVersion = "external-secrets.io/v1beta1"
#     kind       = "ExternalSecret"

#     metadata = {
#       name      = "argocd-external-secrets"
#       namespace = "argocd"
#       labels    = {
#         "argocd.argoproj.io/secret-type" = "repository"
#       }
#     }

#     spec = {
#       refreshInterval = "1h"
#       secretStoreRef = {
#         name = "cluster-secretstore"
#         kind = "ClusterSecretStore"
#       }
#       target = {
#         name = "github-repo-for-greencity-helm"
#         creationPolicy = "Owner"
#       }
#       data = [
#         {
#           secretKey = "url"
#           remoteRef = {
#             key = "greencity_helm_repo_url"
#           }
#         },
#         {
#           secretKey = "username"
#           remoteRef = {
#             key = "greencity_helm_repo_username"
#           }
#         },
#         {
#           secretKey = "password"
#           remoteRef = {
#             key = "greencity_helm_repo_password"
#           }
#         }
#       ]
#     }
#   }

#   depends_on = [
#     helm_release.argocd,
#     helm_release.external_secret_operator,
#     kubernetes_manifest.external_cluster_secret_store 
#   ]
# }

# resource "kubernetes_manifest" "argocd_application_backcore" {

#   manifest = {
#     apiVersion = "argoproj.io/v1alpha1"
#     kind       = "Application"

#     metadata = {
#       name      = "greencity-backcore"
#       namespace = "argocd"
#     }

#     spec = {
#       project = "default"
#       source  = {
#         repoURL        = "https://github.com/lerkasan/greencity-backcore-helm.git"
#         path           = "greencity-backcore"
#         targetRevision = "HEAD"
#       }
#       destination = {
#         namespace = "argocd"
#         server    = "https://kubernetes.default.svc"
#       }
#       syncPolicy  = {
#         automated = {
#           prune    = "true"
#           selfHeal = "true"
#         }
#       }
#     }
#   }

#   depends_on = [
#     helm_release.argocd, 
#     helm_release.external_secret_operator,
#     kubernetes_manifest.external_cluster_secret_store,
#     kubernetes_manifest.argocd_external_secret
#   ]
# }

# resource "kubernetes_manifest" "argocd_application_backuser" {

#   manifest = {
#     apiVersion = "argoproj.io/v1alpha1"
#     kind       = "Application"

#     metadata = {
#       name      = "greencity-backuser"
#       namespace = "argocd"
#     }

#     spec = {
#       project = "default"
#       source  = {
#         repoURL        = "https://github.com/lerkasan/greencity-backcore-helm.git"
#         path           = "greencity-backuser"
#         targetRevision = "HEAD"
#       }
#       destination = {
#         namespace = "argocd"
#         server    = "https://kubernetes.default.svc"
#       }
#       syncPolicy  = {
#         automated = {
#           prune    = "true"
#           selfHeal = "true"
#         }
#       }
#     }
#   }

#   depends_on = [
#     helm_release.argocd, 
#     helm_release.external_secret_operator,
#     kubernetes_manifest.external_cluster_secret_store,
#     kubernetes_manifest.argocd_external_secret
#   ]
# }

# resource "kubernetes_manifest" "argocd_application_frontend" {

#   manifest = {
#     apiVersion = "argoproj.io/v1alpha1"
#     kind       = "Application"

#     metadata = {
#       name      = "greencity-frontend"
#       namespace = "argocd"
#     }

#     spec = {
#       project = "default"
#       source  = {
#         repoURL        = "https://github.com/lerkasan/greencity-backcore-helm.git"
#         path           = "greencity-frontend"
#         targetRevision = "HEAD"
#       }
#       destination = {
#         namespace = "argocd"
#         server    = "https://kubernetes.default.svc"
#       }
#       syncPolicy  = {
#         automated = {
#           prune    = "true"
#           selfHeal = "true"
#         }
#       }
#     }
#   }

#   depends_on = [
#     helm_release.argocd, 
#     helm_release.external_secret_operator,
#     kubernetes_manifest.external_cluster_secret_store,
#     kubernetes_manifest.argocd_external_secret
#   ]
# }

# resource "helm_release" "nexus" {

#   name = "nexus"

#   repository = "https://sonatype.github.io/helm3-charts"
#   chart      = "nxrm-ha"
#   namespace  = "nexus"
#   version    = "68.1.0"

#   create_namespace = true

#   set {
#     name  = "aws.enabled"
#     value = "true"
#   }

#   set {
#     name  = "aws.clusterRegion"
#     value = "us-east-1" # var.aws_region
#   }

#   set {
#     name  = "statefulset.replicaCount"
#     value = "1" # var.nexus_replica_count
#   }

#   set {
#     name  = "statefulset.clustered"
#     value = "false" # var.is_nexus_clustered
#   }

#   set {
#     name  = "statefulset.container.resources.requests.cpu"
#     value = "1"
#   }

#   set {
#     name  = "statefulset.container.resources.requests.memory"
#     value = "2Gi"
#   }

#   set {
#     name  = "statefulset.container.resources.limits.cpu"
#     value = "2"
#   }

#   set {
#     name  = "statefulset.container.resources.limits.memory"
#     value = "4Gi"
#   }

#   set {
#     name  = "statefulset.container.env.nexusDBName"
#     value = "nexus"
#   }

#   set {
#     name  = "secret.dbSecret.enabled"
#     value = "true"
#   }

#   set {
#     name  = "secret.db.user"
#     value = var.nexus_database_username
#   }

#   set {
#     name  = "secret.db.password"
#     value = var.nexus_database_password
#   }

#   set {
#     name  = "secret.db.host"
#     value = var.nexus_db_instance_address
#   }


#   set {
#     name  = "secret.nexusAdminSecret.enabled"
#     value = "true"
#   }

#   set {
#     name  = "secret.nexusAdminSecret.adminPassword"
#     value = var.nexus_ui_password
#   }

#   set {
#     name  = "service.nexus.enabled"
#     value = "true"
#   }

# #   set {
# #     name  = "ingress.enabled"
# #     value = "true"
# #   }

# #   set {
# #     name  = "ingress.host"
# #     value = var.nexus_domain_name
# #   }

# #   set {
# #     name  = "ingress.defaultRule"
# #     value = "true"
# #   }

# #   set {
# #     name  = "ingress.incressClassName"
# #     value = "alb"
# #   }

# #   set {
# #     name  = "ingress.tls.hosts[0]"
# #     value = "nexus.lerkasan.net"
# #     # value = "[ 'nexus.lerkasan.net' ]"
# #   }


# #   set {
# #     name = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/load-balancer-name"
# #     value = "nexus-ingress-alb"
# #   }

# #   set {
# #     name = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/target-type"
# #     value = "ip"
# #   }

# #   set {
# #     name = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/schema"
# #     value = "internet-facing"
# #   }

# #   set {
# #     name = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/backend-protocol"
# #     value = "HTTP"
# #   }

# #   set {
# #     name = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/listen-ports"
# #     value = "[{\"HTTPS\":443}]"
# # 	# value = "[{\"HTTP\":9000}, {\"HTTPS\":443}]"
# #   }

# # #   set {
# # #     name = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/ssl-redirect"
# # #     value = "443"
# # #   }

# #   set {
# #     name = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/certificate-arn"
# #     value = var.nexus_ssl_certificate_arn
# #   }

# #   set {
# #     name = "ingress.annotations.external-dns\\.alpha\\.kubernetes\\.io/hostname"
# #     value = var.nexus_domain_name
# #   }





# #   set {
# #     name  = "server.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
# #     value = "nlb"
# #   }
# #   depends_on = [ module.custom_eks.eks_aws_auth ]
# }


# Configuration for dynamic persistent volume provisioning
# Set storageClass.enabled to true
# Set storageClass.provisioner to efs.csi.aws.com
# Set storageClass.parameters to
#    provisioningMode: efs-ap 
#    fileSystemId: "<your efs file system id>"
#    directoryPerms: "700"
# Set pvc.volumeClaimTemplate.enabled to true

# serviceAccount.enabled	Whether or not to create a Kubernetes Service Account object	false
# serviceAccount.name	The name of a Kubernetes Service Account object to create in order for Nexus Repository pods to access resources as needed	nexus-repository-deployment-sa
# aws.secretmanager.enabled	Set this to true when installing this chart on AWS and you would like the Nexus Repository pod to pull database credentials and license from AWS Secret Manager	false
# aws.externaldns.enabled	Set this to true when installing this chart on AWS and you would like to setup 	false
# aws.externaldns.domainFilter	Domain filter for 	example.com
# aws.externaldns.awsZoneType	The hosted zone type. See 	private
# statefulset.replicaCount	The desired number of Nexus Repository pods	3
# statefulset.clustered	Determines whether or not Nexus Repository should be run in clustered/HA mode. When this is set to false, the search differences  do not apply.	true
# statefulset.container.resources.requests.cpu	The minimum cpu the Nexus repository pod can request	4
# statefulset.container.resources.requests.memory	The minimum memory the Nexus repository pod can request	8Gi
# statefulset.container.resources.limits.cpu	The maximum cpu the Nexus repository pod may get.	4
# statefulset.container.resources.limits.memory	The maximum memory the Nexus repository pod may get.	8Gi
# statefulset.container.env.install4jAddVmParams	Xmx and Xms settings for JVM	-Xms2703m -Xmx2703m
# statefulset.container.env.nexusDBName	The name of the PostgreSQL database to use.	nexus
# statefulset.container.additionalEnv	Additional environment variables for the Nexus Repository container. You can also use this setting to override a default env variable by specifying the same key/name as the default env variable you wish override. Specify this as a block of name and value pairs (e.g., "additionalEnv:- name: foo value: bar- name: foo2 value: bar2")	null
# statefulset.imagePullSecrets	The pull secret for private image registries	{}

# ingress.enabled	Whether or not to create the Ingress	false
# ingress.host	Ingress host	null
# ingress.hostPath	Path for ingress rules.	/
# ingress.dockerSubdomain	Whether or not to add rules for docker subdomains	false
# ingress.defaultRule	Whether or not to add a default rule for the Nexus Repository Ingress which forwards traffic to a Service object	false
# ingress.additionalRules	Additional rules to add to the ingress	null
# ingress.incressClassName	The ingress class name e.g., nginx, alb etc.	null
# ingress.tls.secretName	The name of a Secret object in which to store the TLS secret for ingress	null
# ingress.tls.hosts	A list of TLS hosts	null
# ingress.annotations	Annotations for the Ingress object	nil

# secret.dbSecret.enabled	Whether or not to install database-secret.yaml. Set this to false when using AWS Secret Manager or Azure Key Vault	false
# secret.db.user	The key for secret in AWS Secret manager or Azure Key Vault which contains the database user name. Otherwise if secret.dbSecret.enabled is true, set this to the database user name.	nxrm-db-user
# secret.db.user-alias	Applicable to AWS Secret Manager only. An alias to use for the database user secret retrieved from AWS Secret manager.	nxrm-db-user-alias
# secret.db.password	The key for secret in AWS Secret manager or Azure Key Vault which contains the database password. Otherwise if secret.dbSecret.enabled is true, set this to the database password.	nxrm-db-password
# secret.db.password-alias	Applicable to AWS Secret Manager only. An alias to use for the database password secret retrieved from AWS Secret manager.	nxrm-db-password-alias
# secret.db.host	The key for secret in AWS Secret manager or Azure Key Vault which contains the database host URL. Otherwise if secret.dbSecret.enabled is true, set this to the database host URL.	nxrm-db-host
# secret.db.host-alias	Applicable to AWS Secret Manager only. An alias to use for the database host secret retrieved from AWS Secret manager.	nxrm-db-host-alias
# secret.nexusAdminSecret.enabled	Whether or not to install nexus-admin-secret.yaml. Set this to false when using AWS Secret Manager or Azure Key Vault.	false

# secret.nexusAdminSecret.adminPassword	When secret.nexusAdminSecret.enabled is true, set this to the initial admin password for Nexus Repository. Otherwise ignore.	yourinitialnexuspassword
# secret.nexusAdmin.name	The key for secret in AWS Secret manager or Azure Key Vault which contains the initial Nexus Repository admin password. Otherwise if secret.nexusAdminSecret.enabled is true, then set this to the name for nexus-admin-secret.yaml	nexusAdminPassword
# secret.nexusAdmin.alias	Applicable to AWS Secret Manager only. An alias to use for the initial Nexus Repository admin password secret retrieved from AWS Secret manager.	admin-nxrm-password-alias

# secret.aws.adminpassword.arn	The Amazon Resource Name for the Nexus Repository initial admin secret stored in AWS Secrets Manager. Only applicable if this chart is installed on AWS and you've stored your Nexus Repository initial admin password in AWS Secrets Manager.	arn:aws:secretsmanager:us-east-1:000000000000:secret:admin-nxrm-password
# secret.aws.rds.arn	The Amazon Resource Name for the database secrets stored in AWS Secrets Manager. Only applicable if this chart is installed on AWS and you've stored your database credentials in AWS Secrets Manager.	arn: arn:aws:secretsmanager:us-east-1:000000000000:secret:nxrmrds-cred-nexus





# service.annotations	Common annotations for all Service objects (nexus, docker-registries, nexus-headless)	{}
# service.nexus.enabled	Whether or not to create the Service object	false
# service.nexus.type	The type of the Kubernetes Service	"NodePort"
# service.nexus.protocol	The protocol	TCP
# service.nexus.port	The port to listen for incoming requests	80
# service.headless.annotations	Annotations for the headless service object	{}
# service.headless.publishNotReadyAddresses	Whether or not the service to be discoverable even before the corresponding endpoints are ready	true
# service.nexus.targetPort	The port to forward requests to	8081
# secret.secretProviderClass	The secret provider class for Kubernetes secret store object. See secret.yaml. Set this when using AWS Secret Manager or Azure Key Vault	secretProviderClass
# secret.provider	The provider (e.g. azure, aws etc) for Kubernetes secret store object. Set this when using AWS Secret Manager or Azure Key Vault	provider
