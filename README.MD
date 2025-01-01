## Installation

1. Clone this repository to your local machine:

   ```bash
   git clone https://github.com/sorianfr/kubeadm_aws_multicluster.git

2. Download and Install Terraform
   ```bash
   curl -o terraform.zip https://releases.hashicorp.com/terraform/1.5.6/terraform_1.5.6_linux_amd64.zip && unzip terraform.zip && sudo mv terraform /usr/local/bin/

3. AWS Configure
   
4. Initialize and Apply Terraform
   ```bash
   terraform init
   terraform apply


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

## BGP Peers

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
```
2. Cluster2
```bash
apiVersion: projectcalico.org/v3
kind: CalicoNodeStatus
metadata:
  name: c2-control-plane-status
spec:
  classes:
    - Agent
    - BGP
    - Routes
  node: cluster2controlplane
  updatePeriodSeconds: 10
---
apiVersion: projectcalico.org/v3
kind: CalicoNodeStatus
metadata:
  name: c2-worker-status
spec:
  classes:
    - Agent
    - BGP
    - Routes
  node: cluster2worker1
  updatePeriodSeconds: 10
```
## IPPools

1. Cluster1

```bash
apiVersion: crd.projectcalico.org/v1 
kind: IPPool 
metadata: 
  name: c2-svc-cidr 
spec: 
  cidr: 10.100.0.0/16 
  ipipMode: CrossSubnet 
  disabled: false
---  
apiVersion: crd.projectcalico.org/v1 
kind: IPPool 
metadata: 
  name: c2-pod-cidr 
spec: 
  cidr: 10.245.0.0/16 
  ipipMode: CrossSubnet 
  disabled: false 
```
2. Cluster2
```bash
apiVersion: crd.projectcalico.org/v1 
kind: IPPool 
metadata: 
  name: c1-svc-cidr 
spec: 
  cidr: 10.96.0.0/16 
  ipipMode: CrossSubnet 
  disabled: false
---  
apiVersion: crd.projectcalico.org/v1 
kind: IPPool 
metadata: 
  name: c1-pod-cidr 
spec: 
  cidr: 10.244.0.0/16 
  ipipMode: CrossSubnet 
  disabled: false 
```

## FelixConfiguration

1. Copy & Paste


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
  ```

  

2. Copy & Paste


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


```bash
kubectl create deployment nginx --image=nginx 
```

```bash
kubectl create service nodeport nginx --tcp 80:80 
```




```bash
kubectl run tmp-shell --rm -i --tty --image nicolaka/netshoot   
```

 
```bash
kubectl rollout restart -n kube-system deployment/coredns 
```
