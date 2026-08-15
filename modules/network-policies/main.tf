# ==========================================
# 1. DEFAULT DENY ALL INGRESS & EGRESS
# ==========================================
resource "kubernetes_network_policy_v1" "default_deny" {
  metadata {
    name      = "default-deny-all"
    namespace = var.namespace
  }
  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]
  }
}

# ==========================================
# 2. ALLOW DNS EGRESS (UDP/TCP 53)
# ==========================================
resource "kubernetes_network_policy_v1" "allow_dns_egress" {
  metadata {
    name      = "allow-dns-egress"
    namespace = var.namespace
  }
  spec {
    pod_selector {}
    policy_types = ["Egress"]

    egress {
      ports {
        port     = "53"
        protocol = "UDP"
      }
      ports {
        port     = "53"
        protocol = "TCP"
      }
    }
  }
}

# ==========================================
# 3. UI NETWORK POLICIES
# ==========================================
resource "kubernetes_network_policy_v1" "ui_ingress" {
  metadata {
    name      = "allow-ui-ingress-from-internet"
    namespace = var.namespace
  }
  spec {
    pod_selector {
      match_labels = { "app.kubernetes.io/name" = "ui" }
    }
    policy_types = ["Ingress"]

    ingress {
      ports {
        port     = "8080"
        protocol = "TCP"
      }
    }
  }
}

resource "kubernetes_network_policy_v1" "ui_egress" {
  metadata {
    name      = "allow-ui-egress-to-backends"
    namespace = var.namespace
  }
  spec {
    pod_selector {
      match_labels = { "app.kubernetes.io/name" = "ui" }
    }
    policy_types = ["Egress"]

    egress {
      to {
        pod_selector {
          match_labels = { "app.kubernetes.io/name" = "catalog" }
        }
      }
      to {
        pod_selector {
          match_labels = { "app.kubernetes.io/name" = "carts" }
        }
      }
      to {
        pod_selector {
          match_labels = { "app.kubernetes.io/name" = "orders" }
        }
      }
      to {
        pod_selector {
          match_labels = { "app.kubernetes.io/name" = "checkout" }
        }
      }
      ports {
        port     = "8080"
        protocol = "TCP"
      }
    }
  }
}

# ==========================================
# 4. CATALOG NETWORK POLICIES
# ==========================================
resource "kubernetes_network_policy_v1" "catalog_ingress" {
  metadata {
    name      = "allow-catalog-ingress-from-ui"
    namespace = var.namespace
  }
  spec {
    pod_selector {
      match_labels = { "app.kubernetes.io/name" = "catalog" }
    }
    policy_types = ["Ingress"]

    ingress {
      from {
        pod_selector {
          match_labels = { "app.kubernetes.io/name" = "ui" }
        }
      }
      ports {
        port     = "8080"
        protocol = "TCP"
      }
    }
  }
}

resource "kubernetes_network_policy_v1" "catalog_egress" {
  metadata {
    name      = "allow-catalog-egress-to-rds"
    namespace = var.namespace
  }
  spec {
    pod_selector {
      match_labels = { "app.kubernetes.io/name" = "catalog" }
    }
    policy_types = ["Egress"]

    egress {
      ports {
        port     = "3306"
        protocol = "TCP"
      }
    }
  }
}

# ==========================================
# 5. CARTS NETWORK POLICIES
# ==========================================
resource "kubernetes_network_policy_v1" "carts_ingress" {
  metadata {
    name      = "allow-carts-ingress-from-ui"
    namespace = var.namespace
  }
  spec {
    pod_selector {
      match_labels = { "app.kubernetes.io/name" = "carts" }
    }
    policy_types = ["Ingress"]

    ingress {
      from {
        pod_selector {
          match_labels = { "app.kubernetes.io/name" = "ui" }
        }
      }
      ports {
        port     = "8080"
        protocol = "TCP"
      }
    }
  }
}

resource "kubernetes_network_policy_v1" "carts_egress" {
  metadata {
    name      = "allow-carts-egress-to-dynamodb"
    namespace = var.namespace
  }
  spec {
    pod_selector {
      match_labels = { "app.kubernetes.io/name" = "carts" }
    }
    policy_types = ["Egress"]

    egress {
      to {
        ip_block {
          cidr = "0.0.0.0/0"
        }
      }
      ports {
        port     = "443"
        protocol = "TCP"
      }
    }
  }
}

# ==========================================
# 6. ORDERS NETWORK POLICIES
# ==========================================
resource "kubernetes_network_policy_v1" "orders_ingress" {
  metadata {
    name      = "allow-orders-ingress-from-ui-and-checkout"
    namespace = var.namespace
  }
  spec {
    pod_selector {
      match_labels = { "app.kubernetes.io/name" = "orders" }
    }
    policy_types = ["Ingress"]

    ingress {
      from {
        pod_selector {
          match_labels = { "app.kubernetes.io/name" = "ui" }
        }
      }
      from {
        pod_selector {
          match_labels = { "app.kubernetes.io/name" = "checkout" }
        }
      }
      ports {
        port     = "8080"
        protocol = "TCP"
      }
    }
  }
}

resource "kubernetes_network_policy_v1" "orders_egress" {
  metadata {
    name      = "allow-orders-egress-to-rds-and-rabbitmq"
    namespace = var.namespace
  }
  spec {
    pod_selector {
      match_labels = { "app.kubernetes.io/name" = "orders" }
    }
    policy_types = ["Egress"]

    egress {
      ports {
        port     = "5432"
        protocol = "TCP"
      }
    }
    egress {
      to {
        pod_selector {
          match_labels = { "app.kubernetes.io/name" = "rabbitmq" } # FIXED: Was 'orders'
        }
      }
      ports {
        port     = "5672"
        protocol = "TCP"
      }
    }
  }
}

# ==========================================
# 7. CHECKOUT NETWORK POLICIES
# ==========================================
resource "kubernetes_network_policy_v1" "checkout_ingress" {
  metadata {
    name      = "allow-checkout-ingress-from-ui"
    namespace = var.namespace
  }
  spec {
    pod_selector {
      match_labels = { "app.kubernetes.io/name" = "checkout" }
    }
    policy_types = ["Ingress"]

    ingress {
      from {
        pod_selector {
          match_labels = { "app.kubernetes.io/name" = "ui" }
        }
      }
      ports {
        port     = "8080"
        protocol = "TCP"
      }
    }
  }
}

resource "kubernetes_network_policy_v1" "checkout_egress" {
  metadata {
    name      = "allow-checkout-egress-to-orders-and-redis"
    namespace = var.namespace
  }
  spec {
    pod_selector {
      match_labels = { "app.kubernetes.io/name" = "checkout" }
    }
    policy_types = ["Egress"]

    egress {
      to {
        pod_selector {
          match_labels = { "app.kubernetes.io/name" = "orders" }
        }
      }
      ports {
        port     = "8080"
        protocol = "TCP"
      }
    }
    egress {
      to {
        pod_selector {
          match_labels = { "app.kubernetes.io/name" = "redis" } # FIXED: Was 'checkout'
        }
      }
      ports {
        port     = "6379"
        protocol = "TCP"
      }
    }
  }
}

# ==========================================
# 8. REDIS NETWORK POLICY
# ==========================================
resource "kubernetes_network_policy_v1" "redis_ingress" {
  metadata {
    name      = "allow-redis-ingress-from-checkout"
    namespace = var.namespace
  }
  spec {
    pod_selector {
      match_labels = { "app.kubernetes.io/name" = "redis" } # FIXED: Was 'checkout'
    }
    policy_types = ["Ingress"]

    ingress {
      from {
        pod_selector {
          match_labels = { "app.kubernetes.io/name" = "checkout" }
        }
      }
      ports {
        port     = "6379"
        protocol = "TCP"
      }
    }
  }
}

# ==========================================
# 9. RABBITMQ NETWORK POLICY
# ==========================================
resource "kubernetes_network_policy_v1" "rabbitmq_ingress" {
  metadata {
    name      = "allow-rabbitmq-ingress-from-orders"
    namespace = var.namespace
  }
  spec {
    pod_selector {
      match_labels = { "app.kubernetes.io/name" = "rabbitmq" } # FIXED: Was 'orders'
    }
    policy_types = ["Ingress"]

    ingress {
      from {
        pod_selector {
          match_labels = { "app.kubernetes.io/name" = "orders" }
        }
      }
      ports {
        port     = "5672"
        protocol = "TCP"
      }
    }
  }
}