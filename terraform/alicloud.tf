variable "resource_group" {
  type    = string
  default = "default"
}

variable "region" {
  type    = string
  default = "cn-hongkong"
}

variable "access_key" {
  type = string
}

variable "secret_key" {
  type = string
}

variable "host_image_list" {
  type = list(string)
  default = [
    "win2019_1809_x64_dtc_en-us_40G_container_alibase_20210716.vhd",
    "wincore_1909_x64_dtc_en-us_40G_container_alibase_20200723.vhd",
    "wincore_2004_x64_dtc_en-us_40G_container_alibase_20210716.vhd"
  ]
}

variable "host_password" {
  type = string
}

variable "host_type" {
  type    = string
  default = "ecs.g6e.4xlarge"
}

variable "host_disk_category" {
  type    = string
  default = "cloud_essd"
}

provider "alicloud" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

locals {
  ecs_user_data_template = <<EOF
[powershell]
$env:SSH_USER="root";
$env:SSH_USER_PASSWORD="<PASSWORD>";
Invoke-WebRequest -UseBasicParsing -Uri https://raw.githubusercontent.com/thxCode/terraform-provider-windbag/master/tools/sshd.ps1 | Invoke-Expression;
EOF
}

# resource group
data "alicloud_resource_manager_resource_groups" "default" {
  name_regex = format("^%s$", var.resource_group)
}

# zone 
data "alicloud_zones" "default" {
  available_resource_creation = "Instance"
  available_instance_type     = var.host_type
  available_disk_category     = var.host_disk_category
  instance_charge_type        = "PostPaid"
}

# vpc
resource "alicloud_vpc" "default" {
  resource_group_id = data.alicloud_resource_manager_resource_groups.default.groups.0.id
  vpc_name          = "vpc-golang-windows"
  cidr_block        = "172.16.0.0/12"
}
resource "alicloud_vswitch" "default" {
  zone_id      = data.alicloud_zones.default.zones[0].id
  vpc_id       = alicloud_vpc.default.id
  vswitch_name = "vsw-golang-windows"
  cidr_block   = "172.16.0.0/24"
}

# security group
resource "alicloud_security_group" "default" {
  resource_group_id   = data.alicloud_resource_manager_resource_groups.default.groups.0.id
  vpc_id              = alicloud_vpc.default.id
  description         = "sg-golang-windows"
  name                = "sg-golang-windows"
  security_group_type = "normal"
  inner_access_policy = "Accept"
}
resource "alicloud_security_group_rule" "all_allow_ssh" {
  security_group_id = alicloud_security_group.default.id
  description       = "sg-golang-windows-allow-ssh"
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  port_range        = "22/22"
  priority          = 1
  cidr_ip           = "0.0.0.0/0"
}

# instance
resource "alicloud_instance" "default" {
  count                = length(var.host_image_list)
  description          = var.host_image_list[count.index]
  instance_name        = "ecs-golang-windows-${count.index}"
  image_id             = var.host_image_list[count.index]
  resource_group_id    = data.alicloud_resource_manager_resource_groups.default.groups.0.id
  availability_zone    = data.alicloud_zones.default.zones[0].id
  vswitch_id           = alicloud_vswitch.default.id
  security_groups      = alicloud_security_group.default.*.id
  instance_type        = data.alicloud_zones.default.available_instance_type
  system_disk_category = data.alicloud_zones.default.available_disk_category
  password             = var.host_password
  user_data            = replace(local.ecs_user_data_template, "<PASSWORD>", var.host_password)
}
resource "alicloud_eip_address" "default" {
  count                = length(var.host_image_list)
  description          = var.host_image_list[count.index]
  address_name         = "eip-golang-windows-${count.index}"
  resource_group_id    = data.alicloud_resource_manager_resource_groups.default.groups.0.id
  bandwidth            = 100
  internet_charge_type = "PayByTraffic"
}
resource "alicloud_eip_association" "default" {
  count         = length(var.host_image_list)
  instance_id   = alicloud_instance.default[count.index].id
  allocation_id = alicloud_eip_address.default[count.index].id
}
output "alicloud_eip_public_ip" {
  value = alicloud_eip_address.default.*.ip_address
}
