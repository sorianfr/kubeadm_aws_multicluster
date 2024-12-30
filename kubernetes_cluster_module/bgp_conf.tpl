apiVersion: projectcalico.org/v3 
kind: BGPConfiguration 
metadata: 
  name: default 
spec: 
  logSeverityScreen: Info 
  asNumber: 65001 
  serviceClusterIPs: 
    - cidr: "${service_cidr}"
