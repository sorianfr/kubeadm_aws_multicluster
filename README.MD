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
