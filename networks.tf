data "oci_core_services" "all_oci_services"{}
resource "oci_core_virtual_network" "terraform-vcn" {
  cidr_block     = var.vcn_cidr
  dns_label      = var.vcn_dns_label
  compartment_id = var.compartment_ocid
  display_name   = var.vcn_name
}
resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.vcn_dns_label}igw"
  vcn_id         = oci_core_virtual_network.terraform-vcn.id
}
resource "oci_core_nat_gateway" "ngw" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.vcn_dns_label}ngw"
  vcn_id         = oci_core_virtual_network.terraform-vcn.id
}
resource "oci_core_service_gateway" "sgw"{
  compartment_id = var.compartment_ocid
  display_name   = "${var.vcn_dns_label}sgw"
  vcn_id         = oci_core_virtual_network.terraform-vcn.id
  services {
    service_id= lookup(data.oci_core_services.all_oci_services.services[1],"id")
  }
}
# Public Route Table for API
resource "oci_core_route_table" "PublicRT" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.terraform-vcn.id
  display_name   = "${var.vcn_dns_label}pubrt"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.igw.id
  }
}
# Private Route Table for Node
resource "oci_core_route_table" "PvtRT" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.terraform-vcn.id
  display_name   = "${var.vcn_dns_label}pvtrt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.ngw.id
  }
  route_rules {
    destination       = "all-iad-services-in-oracle-services-network"
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.sgw.id
  }

}

resource "oci_core_subnet" "public_subnet" {
  availability_domain = ""
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_virtual_network.terraform-vcn.id
  cidr_block          = var.public_cidr
  display_name        = var.public_subnet_dns_label
  route_table_id      = oci_core_route_table.PublicRT.id
  security_list_ids   = [oci_core_security_list.public-securitylist.id]
}
resource "oci_core_subnet" "public_lb_subnet" {
  availability_domain = ""
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_virtual_network.terraform-vcn.id
  cidr_block          = var.public_lb_cidr
  display_name        = var.public_lb_subnet_dns_label
  route_table_id      = oci_core_route_table.PublicRT.id
  security_list_ids   = [oci_core_security_list.public-lb-securitylist.id]
}
resource "oci_core_subnet" "private-subnet" {
  availability_domain = ""
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_virtual_network.terraform-vcn.id
  cidr_block          = var.private_cidr
  display_name        = var.private_subnet_dns_label
  route_table_id      = oci_core_route_table.PvtRT.id
  security_list_ids   = [oci_core_security_list.private-securitylist.id]
  prohibit_internet_ingress = true
  prohibit_public_ip_on_vnic = true
}
resource "oci_core_security_list" "public-securitylist" {
  display_name   = "SL_API_public"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.terraform-vcn.id
  
  egress_security_rules {
    protocol    = "6"
    destination = "all-iad-services-in-oracle-services-network"
    destination_type = "SERVICE_CIDR_BLOCK"

    tcp_options {
      min = 443
      max = 443
    }
  }
  egress_security_rules {
    protocol    = "6"
    destination = var.private_cidr
  }
  egress_security_rules {
    protocol    = "1"
    destination = var.private_cidr

      icmp_options {
      code = 4
      type = 3
    }
  }  
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      min = 6443
      max = 6443
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = var.private_cidr

    tcp_options {
      min = 6443
      max = 6443
    }
  }
  ingress_security_rules {
    protocol = "6"
    source   = var.private_cidr

    tcp_options {
      min = 12250
      max = 12250
    }
  }
}
resource "oci_core_security_list" "private-securitylist" {
  display_name   = "SL_Node_private"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.terraform-vcn.id

  egress_security_rules {
    protocol    = "all"
    destination = var.private_cidr
  }
  egress_security_rules {
    protocol    = "6"
    destination = var.public_cidr

    tcp_options {
      min = 6443
      max = 6443
    }
  }  
  egress_security_rules {
    protocol    = "6"
    destination = var.public_cidr

    tcp_options {
      min = 12250
      max = 12250
    }
  }
  egress_security_rules {
    protocol    = "1"
    destination = var.public_cidr

    icmp_options {
      code = 4
      type = 3
    }
  }
  egress_security_rules {
    protocol    = "6"
    destination = "all-iad-services-in-oracle-services-network"
    destination_type = "SERVICE_CIDR_BLOCK"

    tcp_options {
      min = 443
      max = 443
    }
  }
  egress_security_rules {
    protocol    = "1"
    destination = "0.0.0.0/0"

    icmp_options {
      code = 4
      type = 3
    }
  }
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }          
  ingress_security_rules {
    protocol = "all"
    source   = var.private_cidr
  }
  ingress_security_rules {
    protocol = "6"
    source   = var.public_cidr
  }
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      min = 22
      max = 22
    }
  }
  ingress_security_rules {
    protocol = "6"
    source   = var.public_lb_cidr

    tcp_options {
      min = 10256
      max = 10256
    }
  }  
}
resource "oci_core_security_list" "public-lb-securitylist" {
  display_name   = "SL_LB_public"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.terraform-vcn.id
}
