data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_ocid
}

resource "oci_containerengine_node_pool" "nv_node_pool" {
  cluster_id         = oci_containerengine_cluster.kube_cluster.id
  compartment_id     = var.compartment_ocid
  kubernetes_version = var.node_ver
  name               = var.node_name
  node_config_details {
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
      subnet_id           = oci_core_subnet.private-subnet.id
    }
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[1].name
      subnet_id           = oci_core_subnet.private-subnet.id
    }
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[2].name
      subnet_id           = oci_core_subnet.private-subnet.id
    }
    size = var.node_count
  }
  node_shape = var.instance_shape
  node_source_details {
    image_id    = var.image_source_id
    source_type = "image"
  }
  initial_node_labels {
    key   = "name"
    value = var.cluster_name
  }
  ssh_public_key = var.ssh_public_key
}