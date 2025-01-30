
resource "google_project_service" "ressource_manager" {
    service = "cloudresourcemanager.googleapis.com"
}

resource "google_project_service" "ressource_usage" {
    service = "serviceusage.googleapis.com"
    depends_on = [ google_project_service.ressource_manager ]
}

resource "google_project_service" "artifact" {
    service = "artifactregistry.googleapis.com"
    depends_on = [ google_project_service.ressource_manager ]
}

resource "google_project_service" "cloud_build" {
  service = "cloudbuild.googleapis.com"
  depends_on = [ google_project_service.ressource_manager ]
}

resource "google_artifact_registry_repository" "website-tools" {
  provider = google-beta
  project = "${var.project}"
  location      = "${var.region}"
  repository_id = "website-tools"
  format        = "DOCKER"
}

resource "google_sql_database" "database" {
  name     = "wordpress"
  instance = "main-instance"
}

resource "google_sql_user" "wordpress" {
   name     = "wordpress"
   instance = "main-instance"
   password = "ilovedevops"
}

data "google_iam_policy" "noauth" {
   binding {
      role = "roles/run.invoker"
      members = [
         "allUsers",
      ]
   }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
   location    = "${var.region}"
   project     = "${var.project}"
   service     = "${var.service_name}"

   policy_data = data.google_iam_policy.noauth.policy_data
}

resource "google_cloud_run_service" "wordpress_cloud_run" {
  name     = "${var.service_name}"
  location = "${var.region}"
  project = "${var.project}"

  template {
    spec {
      containers {
        ports {
          container_port = 80
        }
        image = "${var.region}-docker.pkg.dev/${var.project}/${var.artifact_repo_name}/image-wordpress:0.1"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}