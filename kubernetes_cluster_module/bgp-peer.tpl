apiVersion: projectcalico.org/v3
kind: BGPPeer
metadata:
  name: bgp-peer-from${source_cluster}-to-${targer_node}-${targer_cluster}
spec:
  nodeSelector: all()
  peerSelector: 
  - ip: ${peer_ip}
    asNumber: ${peer_asn}
  
