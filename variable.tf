variable "tenancy_ocid" {}
variable "compartment_ocid" {}
variable "region" {}
variable "vcn_name" {
    default = "terraform-vcn"
}
variable "vcn_dns_label" {
    default     = "vcn1"
}
variable "vcn_cidr" {}
variable "public_cidr" {}
variable "private_cidr" {}
variable "public_lb_cidr" {}
variable "public_subnet_dns_label" {
    default = "public-subnet"
}
variable "private_subnet_dns_label" {
    default = "private-subnet"
}
variable "public_lb_subnet_dns_label" {
    default = "public-lb-subnet"
}
variable "cluster_name" {}
variable "cluster_ver" {}
variable "node_name" {}
variable "node_ver" {}
variable "node_count" {}
variable "image_source_id" {
    default = "ocid1.image.oc1.iad.aaaaaaaaorro6lk6mljfs3dafptdskbupyjjbindwgqc6nf4ohbe3ucklrqq"
}
variable "instance_shape" {
    default     = "VM.Standard2.1"
}
variable "ssh_public_key" {}