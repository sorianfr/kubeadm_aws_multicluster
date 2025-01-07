apiVersion: projectcalico.org/v3
kind: BGPPeer
metadata:
  name: bgp-peer-${cluster_name}-${peer.peer_ip}
spec:
  nodeSelector: all()
  peerSelector: 
  - ip: ${peer.peer_ip}
    asNumber: ${peer.peer_asn}
  
