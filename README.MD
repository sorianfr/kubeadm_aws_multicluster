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

dfsfsfsdf



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
