
resource "oci_containerengine_cluster" "kube_cluster" {
  compartment_id     = var.compartment_ocid
  kubernetes_version = var.cluster_ver
  name               = var.cluster_name
  vcn_id             = oci_core_virtual_network.terraform-vcn.id
  endpoint_config {
    is_public_ip_enabled = true
    subnet_id            = oci_core_subnet.public_subnet.id
  }
  options {
    add_ons {
      is_kubernetes_dashboard_enabled = false
      is_tiller_enabled               = false
    }
    kubernetes_network_config {
      pods_cidr     = "10.244.0.0/16"
      services_cidr = "10.96.0.0/16"
    }
    service_lb_subnet_ids = [oci_core_subnet.public_lb_subnet.id]
  }
}