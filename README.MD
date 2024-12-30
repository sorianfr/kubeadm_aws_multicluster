## BGP Configuration

1. Cluster1
```bash
apiVersion: projectcalico.org/v3
kind: BGPConfiguration
metadata:
  name: default
spec:
  logSeverityScreen: Info
  asNumber: 65001
  serviceClusterIPs:
    - cidr: 10.96.0.0/16
```
2. Cluster2
```bash
apiVersion: projectcalico.org/v3
kind: BGPConfiguration
metadata:
  name: default
spec:
  logSeverityScreen: Info
  asNumber: 65002
  serviceClusterIPs:
    - cidr: 10.100.0.0/16
```

## BGP Configuration

1. Cluster1
```bash
apiVersion: projectcalico.org/v3  
kind: BGPPeer  
metadata:  
  name: bgp2c2-control  
spec:  
  peerIP: 10.0.3.10
  asNumber: 65002  
---  
apiVersion: projectcalico.org/v3  
kind: BGPPeer  
metadata:  
  name: bgp2c2-worker  
spec:  
  peerIP: 10.0.3.11
  asNumber: 65002 
```
2. Cluster2
```bash
apiVersion: projectcalico.org/v3  
kind: BGPPeer  
metadata:  
  name: bgp2c1-control  
spec:  
  peerIP: 10.0.2.10
  asNumber: 65001  
---  
apiVersion: projectcalico.org/v3  
kind: BGPPeer  
metadata:  
  name: bgp2c1-worker  
spec:  
  peerIP: 10.0.2.11
  asNumber: 65001 
```


## Calico Node Status
1. Cluster1
```bash
apiVersion: projectcalico.org/v3
kind: CalicoNodeStatus
metadata:
  name: c1-control-plane-status
spec:
  classes:
    - Agent
    - BGP
    - Routes
  node: cluster1controlplane
  updatePeriodSeconds: 10
---
apiVersion: projectcalico.org/v3
kind: CalicoNodeStatus
metadata:
  name: c1-worker-status
spec:
  classes:
    - Agent
    - BGP
    - Routes
  node: cluster1worker1
  updatePeriodSeconds: 10
EOF
```
2. Cluster2
```bash
apiVersion: projectcalico.org/v3
kind: CalicoNodeStatus
metadata:
  name: c1-control-plane-status
spec:
  classes:
    - Agent
    - BGP
    - Routes
  node: cluster1controlplane
  updatePeriodSeconds: 10
---
apiVersion: projectcalico.org/v3
kind: CalicoNodeStatus
metadata:
  name: c1-worker-status
spec:
  classes:
    - Agent
    - BGP
    - Routes
  node: cluster1worker1
  updatePeriodSeconds: 10
EOF
```

## FelixConfiguration

1. Copy & Paste

  ```bash
  kubectl patch felixconfiguration default --type='merge' -p "$(cat <<EOF
  {
    "spec": {
      "externalNodesList": [
        "$(nslookup cluster1controlplane | grep Address | tail -n 1 | awk '{print $2}')/32",
        "$(nslookup cluster1worker1 | grep Address | tail -n 1 | awk '{print $2}')/32"
      ]
    }
  }
  EOF
  )"
```


2. Copy & Paste


  ```bash
  kubectl patch felixconfiguration default --type='merge' -p "$(cat <<EOF
  {
    "spec": {
      "externalNodesList": [
        "$(nslookup cluster2controlplane | grep Address | tail -n 1 | awk '{print $2}')/32",
        "$(nslookup cluster2worker1 | grep Address | tail -n 1 | awk '{print $2}')/32"
      ]
    }
  }
  EOF
  )"
