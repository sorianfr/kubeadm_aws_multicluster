clusters = [
  {
    cluster_name                    = "k8s_cluster1"
    private_subnet_cidr_block = "10.0.2.0/24"
    controlplane_private_ip  = "10.0.2.10"
    pod_subnet              = "10.244.0.0/16"
    service_cidr            = "10.96.0.0/16"
    worker_count            = 1
  },
  {
    cluster_name                    = "k8s_cluster2"
    private_subnet_cidr_block = "10.0.3.0/24"
    controlplane_private_ip = "10.0.3.10"
    pod_subnet              = "10.245.0.0/16"
    service_cidr            = "10.100.0.0/16"
    worker_count            = 1
  }
]
