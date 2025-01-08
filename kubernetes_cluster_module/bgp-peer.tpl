apiVersion: projectcalico.org/v3
kind: BGPPeer
metadata:
  name: bgp-peer-from${cluster_name}-to-${targer_node}-${targer_cluster}
spec:
  nodeSelector: all()
  peerSelector: 
  - ip: ${peer.peer_ip}
    asNumber: ${peer.peer_asn}
  
