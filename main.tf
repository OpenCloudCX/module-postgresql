terraform {
  required_providers {
    kubernetes = {}
    helm       = {}
  }
}

resource "aws_secretsmanager_secret" "postgres_root" {
  name                    = "postgres_root"
  recovery_window_in_days = 0
}

resource "random_password" "postgres_root" {
  length           = 24
  special          = true
  override_special = "_%@"
}

resource "aws_secretsmanager_secret_version" "postgres_root" {
  secret_id     = aws_secretsmanager_secret.postgres_root.id
  secret_string = "{\"password\": \"${random_password.postgres_root.result}\"}"
}

resource "kubernetes_secret" "postgres_root" {
  metadata {
    name      = "postgres-root-password"
    namespace = "develop"
    labels = {
      "ConnectOutput" = "true"
    }
  }

  data = {
    password = random_password.postgres_root.result
  }

  type = "kubernetes.io/basic-auth"
}

resource "helm_release" "postgres" {
  name             = "postgres"
  chart            = var.helm_chart_name
  namespace        = var.namespace
  repository       = var.helm_chart
  timeout          = var.helm_timeout
  version          = var.helm_version
  create_namespace = false
  reset_values     = false

  set {
    name  = "global.postgresql.postgresqlPassword"
    value = random_password.postgres_root.result
  }
}



























