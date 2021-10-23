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
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }
  part {
    content_type = "text/cloud-config"
    content      = templatefile("${path.module}/templates/docker.tpl", { keep_disk = var.keep_disk })
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }
  part {
    content_type = "text/cloud-config"
    content      = file("${path.module}/templates/cardano.yml")
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }
}

data "cloudinit_config" "shared" {

  part {
    content_type = "text/cloud-config"
    content      = file("${path.module}/templates/default.yml")
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }
  part {
    content_type = "text/cloud-config"
    content      = templatefile("${path.module}/templates/docker.tpl", { keep_disk = var.keep_disk })
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }
  part {
    content_type = "text/cloud-config"
    content      = file("${path.module}/templates/shared.yml")
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }
}
