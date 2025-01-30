data "google_client_config" "default" {}

data "google_container_cluster" "my_cluster" {
   name     = "gke-dauphine"
   location = "us-central1-a"
}

provider "kubernetes" {
   host                   = data.google_container_cluster.my_cluster.endpoint
   token                  = data.google_client_config.default.access_token
   cluster_ca_certificate = base64decode(data.google_container_cluster.my_cluster.master_auth.0.cluster_ca_certificate)
}

resource "kubernetes_namespace" "wordpress_ns" {
  metadata {
    name = "wordpress"
  }
}

# Deploy MySQL Database
resource "kubernetes_deployment" "mysql" {
  metadata {
    name      = "mysql"
    namespace = kubernetes_namespace.wordpress_ns.metadata[0].name
    labels = {
      app = "mysql"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "mysql"
      }
    }

    template {
      metadata {
        labels = {
          app = "mysql"
        }
      }

      spec {
        container {
          name  = "mysql"
          image = "mysql:5.7"

          env {
            name  = "MYSQL_ROOT_PASSWORD"
            value = "rootpassword"
          }

          env {
            name  = "MYSQL_DATABASE"
            value = "wordpress"
          }

          env {
            name  = "MYSQL_USER"
            value = "wordpress"
          }

          env {
            name  = "MYSQL_PASSWORD"
            value = "wordpresspassword"
          }

          port {
            container_port = 3306
          }
        }
      }
    }
  }
}

# Create MySQL Service
resource "kubernetes_service" "mysql" {
  metadata {
    name      = "mysql"
    namespace = kubernetes_namespace.wordpress_ns.metadata[0].name
  }

  spec {
    selector = {
      app = "mysql"
    }

    port {
      port        = 3306
      target_port = 3306
    }
  }
}

# Deploy WordPress Application
resource "kubernetes_deployment" "wordpress" {
  metadata {
    name      = "wordpress"
    namespace = kubernetes_namespace.wordpress_ns.metadata[0].name
    labels = {
      app = "wordpress"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "wordpress"
      }
    }

    template {
      metadata {
        labels = {
          app = "wordpress"
        }
      }

      spec {
        container {
          name  = "wordpress"
          image = "wordpress:latest"

          env {
            name  = "WORDPRESS_DB_HOST"
            value = "mysql.wordpress.svc.cluster.local:3306"
          }

          env {
            name  = "WORDPRESS_DB_USER"
            value = "wordpress"
          }

          env {
            name  = "WORDPRESS_DB_PASSWORD"
            value = "wordpresspassword"
          }

          env {
            name  = "WORDPRESS_DB_NAME"
            value = "wordpress"
          }

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

# Expose WordPress using a LoadBalancer
resource "kubernetes_service" "wordpress" {
  metadata {
    name      = "wordpress"
    namespace = kubernetes_namespace.wordpress_ns.metadata[0].name
  }

  spec {
    selector = {
      app = "wordpress"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}