# https://www.terraform.io/docs/configuration/expressions.html
provider "google" {
  project         = "securethebox-server"
  region          = "us-central1"
  zone            = "us-central1-a"
}

provider "google-beta" {
  # credentials = using env value GOOGLE_CLOUD_KEYFILE_JSON
  project         = "securethebox-server"
  region          = "us-central1"
  zone            = "us-central1-a"

  # --release-channel stable
  release_channel { 
    channel = "STABLE"
  }

  # --addons CloudRun
  addons_config {
    istio_config {
      disabled = false
    }
    cloudrun_config {
      disabled = false
    }
  }
}

resource "google_container_cluster" "primary" {
  name     =  "${var.kubernetes_cluster_name}"
  location = "us-central1"
  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = false
  initial_node_count = 4

  # --no-enable-basic-auth
  master_auth {
    username = ""
    password = ""
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  node_config {
    preemptible  = true
    machine_type = "n1-standard-1"
    disk_size_gb = 100
    image_type = "COS"
    disk_type = "pd-standard"
    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/ndev.clouddns.readwrite",
      "https://www.googleapis.com/auth/trace.append"
    ]
  }
  # --enable-ip-alias
  ip_allocation_policy {
  }
  
  default_max_pods_per_node = 8

  network = "projects/securethebox-server/global/networks/default"
  subnetwork = "projects/securethebox-server/regions/us-central1/subnetworks/default"

  addons_config {
    horizontal_pod_autoscaling {
      disabled = false
    }
    http_load_balancing {
      disabled = false
    }
  }
}
