# ---------------------------
# TEMPLATE FILE
# ---------------------------

# Configure the Template Provider
provider "cloudinit" {
}
# ---------------------------
# TEMPLATE CLOUD-INIT CONFIG
# ---------------------------
data "cloudinit_config" "default" {

  part {
    content_type = "text/cloud-config"
    content      = file("${path.module}/templates/default.yml")
  }
  part {
    content_type = "text/cloud-config"
    content      = file("${path.module}/templates/docker.yml")
  }
}
