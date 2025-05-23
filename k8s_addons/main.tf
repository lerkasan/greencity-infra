data "aws_eks_cluster" "default" {
  name = var.eks_cluster_name
}

resource "kubernetes_annotations" "default-storageclass" {
  api_version = "storage.k8s.io/v1"
  kind        = "StorageClass"
  force       = "true"

  metadata {
    name = "gp2"
  }
  annotations = {
    "storageclass.kubernetes.io/is-default-class" = "true"
  }
}

resource "kubernetes_manifest" "argocd_external_secrets_service_account" {

  manifest = {
    apiVersion = "v1"
    kind       = "ServiceAccount"

    metadata = {
      name      = "external-secrets-account"
      namespace = "argocd"
      annotations = {
        "eks.amazonaws.com/role-arn" = var.external_secrets_irsa_role_arn
      }
    }
  }
}

resource "kubernetes_manifest" "external_cluster_secret_store" {

  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ClusterSecretStore"

    metadata = {
      name = "cluster-secretstore"
    }

    spec = {
      provider = {
        aws = {
          service = "ParameterStore"
          region  = var.aws_region
          auth = {
            jwt = {
              serviceAccountRef = {
                name = "external-secrets-account"
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_manifest" "argocd_external_secret" {

  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"

    metadata = {
      name      = "argocd-external-secrets"
      namespace = "argocd"
      labels = {
        "argocd.argoproj.io/secret-type" = "repository"
      }
    }

    spec = {
      refreshInterval = "1h"
      secretStoreRef = {
        name = "cluster-secretstore"
        kind = "ClusterSecretStore"
      }
      target = {
        name           = "github-repo-for-greencity-helm"
        creationPolicy = "Owner"
      }
      data = [
        {
          secretKey = "url"
          remoteRef = {
            key = "greencity_helm_repo_url"
          }
        },
        {
          secretKey = "username"
          remoteRef = {
            key = "greencity_helm_repo_username"
          }
        },
        {
          secretKey = "password"
          remoteRef = {
            key = "greencity_helm_repo_password"
          }
        }
      ]
    }
  }

  depends_on = [
    kubernetes_manifest.external_cluster_secret_store
  ]
}

resource "kubernetes_manifest" "argocd_application_backcore" {

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"

    metadata = {
      name      = var.greencity_backcore_chart_name
      namespace = "argocd"
    }

    spec = {
      project = "default"
      source = {
        repoURL        = var.greencity_helm_repo_url
        path           = var.greencity_backcore_chart_name
        targetRevision = "HEAD"
      }
      destination = {
        namespace = "argocd"
        server    = "https://kubernetes.default.svc"
      }
      syncPolicy = {
        automated = {
          prune    = "true"
          selfHeal = "true"
        }
      }
    }
  }

  depends_on = [
    kubernetes_manifest.external_cluster_secret_store,
    kubernetes_manifest.argocd_external_secret
  ]
}

resource "kubernetes_manifest" "argocd_application_backuser" {

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"

    metadata = {
      name      = var.greencity_backuser_chart_name
      namespace = "argocd"
    }

    spec = {
      project = "default"
      source = {
        repoURL        = var.greencity_helm_repo_url
        path           = var.greencity_backuser_chart_name
        targetRevision = "HEAD"
      }
      destination = {
        namespace = "argocd"
        server    = "https://kubernetes.default.svc"
      }
      syncPolicy = {
        automated = {
          prune    = "true"
          selfHeal = "true"
        }
      }
    }
  }

  depends_on = [
    kubernetes_manifest.external_cluster_secret_store,
    kubernetes_manifest.argocd_external_secret
  ]
}

resource "kubernetes_manifest" "argocd_application_frontend" {

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"

    metadata = {
      name      = var.greencity_frontend_chart_name
      namespace = "argocd"
    }

    spec = {
      project = "default"
      source = {
        repoURL        = var.greencity_helm_repo_url
        path           = var.greencity_frontend_chart_name
        targetRevision = "HEAD"
      }
      destination = {
        namespace = "argocd"
        server    = "https://kubernetes.default.svc"
      }
      syncPolicy = {
        automated = {
          prune    = "true"
          selfHeal = "true"
        }
      }
    }
  }

  depends_on = [
    kubernetes_manifest.external_cluster_secret_store,
    kubernetes_manifest.argocd_external_secret
  ]
}

resource "kubernetes_manifest" "argocd_ingress" {

  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "Ingress"

    metadata = {
      name      = "argocd"
      namespace = "argocd"
      annotations = {
        "alb.ingress.kubernetes.io/load-balancer-name" = "argocd-ingress-alb"
        "alb.ingress.kubernetes.io/target-type"        = "ip"
        "alb.ingress.kubernetes.io/scheme"             = "internet-facing"
        "alb.ingress.kubernetes.io/group.name"         = "argocd-ingress-group"
        "alb.ingress.kubernetes.io/backend-protocol"   = "HTTPS"
        "alb.ingress.kubernetes.io/listen-ports"       = "[{\"HTTPS\":443}]"
        "alb.ingress.kubernetes.io/certificate-arn"    = var.argocd_ssl_cert_arn
        "external-dns.alpha.kubernetes.io/hostname"    = var.argocd_hostname
      }
    }

    spec = {
      ingressClassName = "alb"
      tls = [{
        hosts = [var.argocd_hostname]
      }]
      rules = [{
        host = var.argocd_hostname
        http = {
          paths = [{
            path     = "/"
            pathType = "Prefix"
            backend = {
              service = {
                name = "argocd-server"
                port = {
                  number = "443"
                }
              }
            }
          }]
        }
      }]
    }
  }
}


resource "kubernetes_manifest" "sonarqube_ingress" {

  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "Ingress"

    metadata = {
      name      = "sonarqube"
      namespace = "sonarqube"
      annotations = {
        "alb.ingress.kubernetes.io/load-balancer-name" = "sonarqube-ingress-alb"
        "alb.ingress.kubernetes.io/target-type"        = "ip"
        "alb.ingress.kubernetes.io/scheme"             = "internet-facing"
        "alb.ingress.kubernetes.io/group.name"         = "sonarqube-ingress-group"
        "alb.ingress.kubernetes.io/backend-protocol"   = "HTTP"
        "alb.ingress.kubernetes.io/listen-ports"       = "[{\"HTTPS\":443}]"
        "alb.ingress.kubernetes.io/certificate-arn"    = var.sonarqube_ssl_cert_arn
        "external-dns.alpha.kubernetes.io/hostname"    = var.sonarqube_hostname
      }
    }

    spec = {
      ingressClassName = "alb"
      tls = [{
        hosts = [var.sonarqube_hostname]
      }]
      rules = [{
        host = var.sonarqube_hostname
        http = {
          paths = [{
            path     = "/"
            pathType = "Prefix"
            backend = {
              service = {
                name = "sonarqube-sonarqube"
                port = {
                  number = "9000"
                }
              }
            }
          }]
        }
      }]
    }
  }
}


resource "kubernetes_manifest" "grafana_ingress" {

  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "Ingress"

    metadata = {
      name      = "grafana"
      namespace = "monitoring"
      annotations = {
        "alb.ingress.kubernetes.io/load-balancer-name" = "grafana-ingress-alb"
        "alb.ingress.kubernetes.io/target-type"        = "ip"
        "alb.ingress.kubernetes.io/scheme"             = "internet-facing"
        "alb.ingress.kubernetes.io/group.name"         = "grafana-ingress-group"
        "alb.ingress.kubernetes.io/backend-protocol"   = "HTTP"
        "alb.ingress.kubernetes.io/listen-ports"       = "[{\"HTTPS\":443}]"
        "alb.ingress.kubernetes.io/certificate-arn"    = var.grafana_ssl_cert_arn
        "external-dns.alpha.kubernetes.io/hostname"    = var.grafana_hostname
      }
    }

    spec = {
      ingressClassName = "alb"
      tls = [{
        hosts = [var.grafana_hostname]
      }]
      rules = [{
        host = var.grafana_hostname
        http = {
          paths = [{
            path     = "/"
            pathType = "Prefix"
            backend = {
              service = {
                name = "kube-prometheus-stack-grafana"
                port = {
                  number = "80"
                }
              }
            }
          }]
        }
      }]
    }
  }
}

resource "helm_release" "artifactory" {

  name = "artifactory"

  repository = "https://charts.jfrog.io"
  chart      = "artifactory-oss"
  namespace  = "artifactory-oss"
  version    = "107.84.16"

  timeout = 600

  create_namespace = true

  set_sensitive {
    name  = "artifactory.postgresql.postgresqlPassword"
    value = var.artifactory_database_password
  }

  set_sensitive {
    name  = "artifactory.artifactory.admin.ip"
    value = var.artifactory_ui_ip
  }

  set_sensitive {
    name  = "artifactory.artifactory.admin.username"
    value = var.artifactory_ui_username
  }

  set_sensitive {
    name  = "artifactory.artifactory.admin.password"
    value = var.artifactory_ui_password
  }

  set {
    name  = "artifactory.nginx.enabled"
    value = "false"
  }

  set {
    name  = "artifactory.ingress.enabled"
    value = "true"
  }

  set {
    name  = "artifactory.ingress.hosts[0]"
    value = var.artifactory_domain_name
  }

  set {
    name  = "artifactory.ingress.tls[0].hosts[0]"
    value = var.artifactory_domain_name
  }

  set {
    name  = "artifactory.ingress.className"
    value = "alb"
  }

  set {
    name  = "artifactory.artifactory.service.type"
    value = "NodePort"
  }

  set {
    name  = "artifactory.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/load-balancer-name"
    value = "artifactory-ingress-alb"
  }

  set {
    name  = "artifactory.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/target-type"
    value = "ip"
  }

  set {
    name  = "artifactory.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/scheme"
    value = "internet-facing"
  }

  set {
    name  = "artifactory.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/backend-protocol"
    value = "HTTP"
  }

  set {
    name  = "artifactory.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/listen-ports"
    value = "[{\"HTTPS\":443}]"
  }

  set_sensitive {
    name  = "artifactory.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/certificate-arn"
    value = var.artifactory_ssl_certificate_arn
  }

  set {
    name  = "artifactory.ingress.annotations.external-dns\\.alpha\\.kubernetes\\.io/hostname"
    value = var.artifactory_domain_name
  }

  depends_on = [kubernetes_annotations.default-storageclass]
}
