provider "google" {
  credentials = file(var.credentials_file)

  project = var.project
  region  = var.region
  zone    = var.zone
}

resource "random_string" "password" {
 length = 16
 special = true
}

resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "google_sql_database_instance" "master" {
  name             = "project-x-instance-${random_id.db_name_suffix.hex}"
  database_version = "MYSQL_5_7"
  region           = var.region

  settings {
    # Second-generation instance tiers are based on the machine
    # type. See argument reference below.
    tier = "db-f1-micro"
  }
}

resource "google_sql_user" "users" {
  name     = "root"
  instance = google_sql_database_instance.master.name
  password = random_string.password.result
}

resource "google_sql_database" "database" {
  name     = "DB_1"
  instance = google_sql_database_instance.master.name
}

resource "google_service_account" "myaccount" {
  account_id   = "testmyaccount"
  display_name = "My Service Account"
}

resource "google_service_account_key" "mykey" {
  service_account_id = google_service_account.myaccount.name
}

resource "google_project_iam_binding" "myaccount" {
  project = var.project
  role    = "roles/editor"
  members = [
    "serviceAccount:${google_service_account.myaccount.email}"
  ]
}


resource "google_container_cluster" "my_cluster" {
  name               = "martys-cluster"
  location           = var.zone
  initial_node_count = 1


  node_config {
    machine_type = "n1-standard-1"
    service_account = google_service_account.myaccount.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append",
      "https://www.googleapis.com/auth/servicecontrol",
    ]

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

resource "local_file" "test" {
    content  = "rootPw: \"${random_string.password.result}\"\n\ninstanceName: ${var.project}:${var.region}:${google_sql_database_instance.master.name}\n\ncredentials_json: ${base64decode(google_service_account_key.mykey.private_key)}\nproject: ${var.project}"
    filename = "values.yaml"
}
