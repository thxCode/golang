variable "image_repository" {
  type    = string
  default = "thxcode"
}

variable "image_name" {
  type    = string
  default = "golang"
}

variable "image_tag" {
  type    = string
  default = "1.17.3-windowsservercore"
}

variable "image_registry_username" {
  type = string
}

variable "image_registry_password" {
  type = string
}

provider "windbag" {
  docker {
    version = "19.03"
  }
}

locals {
  image_registry = length(split("/", var.image_repository)) == 2 ? element(split("/", var.image_repository), 0) : "docker.io"
}

# image
resource "windbag_image" "default" {
  tag          = [join(":", [join("/", [var.image_repository, var.image_name]), var.image_tag])]
  push_timeout = "3h"

  build_arg_release_mapper {
    release = "1809"
    build_arg = {
      "BUILDER_IMAGE_TAG" = "10.0.17763.2114"
    }
  }
  build_arg_release_mapper {
    release = "1909"
    build_arg = {
      "BUILDER_IMAGE_TAG" = "10.0.18363.1556"
    }
  }
  build_arg_release_mapper {
    release = "2004"
    build_arg = {
      "BUILDER_IMAGE_TAG" = "10.0.19041.1165"
    }
  }

  registry {
    address       = local.image_registry
    username      = var.image_registry_username
    password      = var.image_registry_password
    login_timeout = "30m"
  }

  dynamic "worker" {
    for_each = alicloud_eip_address.default.*.ip_address
    content {
      address = format("%s:22", worker.value)
      ssh {
        username = "root"
        password = var.host_password
      }
    }
  }

  timeouts {
    create = "2h"
    read   = "6h"
    update = "12h"
  }
}
