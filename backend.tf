terraform {
  backend "gcs" {
    prefix = "terraform/state"
    ## initially inited like in ./00_setup/terraform_init.sh
    # credentials = var.GCP_PROJECT_SERVICE_ACCOUNT_FILE
    # bucket  = var.TF_STATE_BUCKET
    # project = var.PROJECT_ID
  }
}
