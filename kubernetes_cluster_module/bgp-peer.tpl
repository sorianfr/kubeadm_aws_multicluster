apiVersion: projectcalico.org/v3
kind: BGPPeer
metadata:
  name: bgp-peer-{{ cluster_name }}
spec:
  nodeSelector: all()
  peerSelector: |
  {% for peer in jsondecode(bgp_peers) %}
  - ip: {{ peer.peer_ip }}
    asNumber: {{ peer.peer_asn }}
  {% endfor %}
