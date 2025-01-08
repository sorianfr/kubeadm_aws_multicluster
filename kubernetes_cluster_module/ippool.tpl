apiVersion: crd.projectcalico.org/v1 
kind: IPPool 
metadata: 
  name: c2-svc-cidr 
spec: 
  cidr: 10.100.0.0/16 
  ipipMode: CrossSubnet 
  disabled: true 

---  

apiVersion: crd.projectcalico.org/v1 
kind: IPPool 
metadata: 
  name: c2-pod-cidr 
spec: 
  cidr: 10.245.0.0/16 
  ipipMode: CrossSubnet 
  disabled: true 
