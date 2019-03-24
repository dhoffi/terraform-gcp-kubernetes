#Global Vars
dest = "devtest"
env  = "dev"

how_many_jumpboxs = 1
how_many_master_nodes = 2
how_many_worker_nodes = 2

#VPC Vars
# single mgmt subnet to rule them all
mgmt_subnet_cidr = "10.0.0.0/24"
# one subnet per compute zone (limited by var.global_how_many_compute_zones)
private_subnet_cidr = "10.0.1.0/24"
public_subnet_cidr = "10.0.5.0/24"
