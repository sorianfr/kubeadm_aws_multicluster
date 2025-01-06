    terraform {
      required_providers {
        aws = {
          source  = "hashicorp/aws"
          version = "~> 4.0"
        }
      }
    }
    
    # Private Subnet
    resource "aws_subnet" "k8s_private_subnet" {
      vpc_id                  = var.vpc_id
      cidr_block              = var.private_subnet_cidr_block
      map_public_ip_on_launch = false
      availability_zone       = var.availability_zone

      tags = {
        Name = "${var.cluster_name}_private_subnet"
      }
    }


    # Associate Private Subnet with Private Route Table
    resource "aws_route_table_association" "private_rta" {
      subnet_id      = aws_subnet.k8s_private_subnet.id
      route_table_id = var.private_route_table_id
    }

    locals {
          sg_name = "k8s_sg_${var.cluster_name}"
    }

    # Security Group
    resource "aws_security_group" "k8s_sg" {
      name        = local.sg_name
      vpc_id = var.vpc_id

      ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        security_groups = [var.public_sg_id] # Allow SSH from the bastion
      }

      ingress {
        from_port   = 6443
        to_port     = 6443
        protocol    = "tcp"
        cidr_blocks = [var.vpc_cidr_block] # Kubernetes API access within VPC
      }

      ingress {
        from_port   = 30000
        to_port     = 32767
        protocol    = "tcp"
        cidr_blocks = [var.vpc_cidr_block] # NodePort range within VPC
      }

      ingress {
        from_port   = 10250
        to_port     = 10250
        protocol    = "tcp"
        cidr_blocks = [var.vpc_cidr_block] # # Kubelet communication within VPC
      }
    
      ingress {
        from_port   = 5473
        to_port     = 5473
        protocol    = "tcp"
        cidr_blocks = [var.vpc_cidr_block] # Service communication within VPC
      }

      # BGP for Calico
      ingress {
        from_port   = 179
        to_port     = 179
        protocol    = "tcp"
        cidr_blocks = [var.vpc_cidr_block] # Ensure this matches the pod network CIDR
      }

      # Allow VXLAN for Calico (UDP 4789)
      ingress {
        from_port   = 4789
        to_port     = 4789
        protocol    = "udp"
        cidr_blocks = [var.pod_subnet] # Pod network CIDR
      }

      # Allow pod-to-pod communication within the cluster
      ingress {
        from_port   = 0
        to_port     = 65535
        protocol    = "tcp"
        cidr_blocks = [var.pod_subnet] # Pod network CIDR
      }

      # Allow IP-in-IP (used by Calico)
      ingress {
        from_port   = -1
        to_port     = -1
        protocol    = "4" # Protocol 4 is for IP-in-IP
        cidr_blocks = [var.pod_subnet] # Pod network CIDR
      }

      ingress {
        from_port   = -1
        to_port     = -1
        protocol    = "4" # Protocol 4 is for IP-in-IP
        cidr_blocks = [var.vpc_cidr_block] # Pod network CIDR
      }

      # etcd Communication (Control Plane Only)
      ingress {
        from_port   = 2379
        to_port     = 2380
        protocol    = "tcp"
        cidr_blocks = ["${var.controlplane_private_ip}/32"] # Restrict to control plane's private IP
      }

      ingress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1" 
        cidr_blocks = [var.pod_subnet] # Pod network CIDR
      }

      ingress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1" 
        cidr_blocks = [var.vpc_cidr_block] # Pod network CIDR
      }   

      egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }

      tags = {
        Name = "k8s_sg"
      }
    }

    resource "aws_security_group_rule" "ssh_within_group" {
      type                     = "ingress"
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      security_group_id        = aws_security_group.k8s_sg.id
      source_security_group_id = aws_security_group.k8s_sg.id
      description              = "Allow SSH within the security group"
    }

    

    # User Data for Kubernetes setup on the Control Plane
        data "template_file" "controlplane_user_data" {
          template = <<-EOF
            #!/bin/bash
            # Set hostname for the control plane node
            hostnamectl set-hostname ${var.cluster_name}controlplane
        
            # Download and execute the setup script
            curl -O https://raw.githubusercontent.com/sorianfr/kubeadm_multinode_cluster_vagrant/master/setup_k8s_ec2.sh
            chmod +x /setup_k8s_ec2.sh
            /setup_k8s_ec2.sh
          EOF
        }


    # User Data for Workers  
    data "template_file" "worker_user_data" {
      count    = var.worker_count
      template = <<-EOF
        #!/bin/bash
        # Set hostname for worker${count.index + 1}
        hostnamectl set-hostname ${var.cluster_name}worker${count.index + 1}

        # Download and execute the setup script
        curl -O https://raw.githubusercontent.com/sorianfr/kubeadm_multinode_cluster_vagrant/master/setup_k8s_ec2.sh
        chmod +x /setup_k8s_ec2.sh
        /setup_k8s_ec2.sh
      EOF
    }



    # Control Plane Instance
    resource "aws_instance" "controlplane" {
      ami                         = var.ami_id
      instance_type               = var.instance_type
      subnet_id                   = aws_subnet.k8s_private_subnet.id
      vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
      iam_instance_profile        = var.iam_instance_profile
      key_name                    = var.key_name
      private_ip                  = var.controlplane_private_ip
      user_data                   = data.template_file.controlplane_user_data.rendered


      source_dest_check           = false  # Disable Source/Destination Check

      tags = {
        Name = "${var.cluster_name}_controlplane"
      }
        

    }

    # Worker Node Instances
    resource "aws_instance" "workers" {
      count                       = var.worker_count
      ami                         = var.ami_id
      instance_type               = var.instance_type
      subnet_id                   = aws_subnet.k8s_private_subnet.id
      vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
      iam_instance_profile        = var.iam_instance_profile
      key_name                    = var.key_name
      private_ip                  = cidrhost(var.private_subnet_cidr_block, 11 + count.index)
      user_data                   = data.template_file.worker_user_data[count.index].rendered

      source_dest_check           = false  # Disable Source/Destination Check

      tags = {
        Name = "${var.cluster_name}_worker${count.index + 1}"
      }

    }


    data "template_file" "kubeadm_config" {
      template = file("${path.module}/kubeadm-config.tpl")
      vars = {
        cluster_name    = var.cluster_name
        controlplane_ip = var.controlplane_private_ip
        pod_subnet      = var.pod_subnet
        service_cidr      = var.service_cidr

      }
    }

    resource "local_file" "kubeadm_config" {
      filename = "${path.module}/kubeadm-config-${var.cluster_name}.yaml"
      content  = data.template_file.kubeadm_config.rendered
    }

    data "template_file" "custom_resources" {
      template = file("${path.module}/custom-resources.tpl")
      vars = {
        cluster_name    = var.cluster_name
        pod_subnet    = var.pod_subnet
        encapsulation = var.encapsulation
      }
    }

    resource "local_file" "custom_resources" {
      filename = "${path.module}/custom-resources-${var.cluster_name}.yaml"
      content  = data.template_file.custom_resources.rendered
    }

    data "template_file" "bgp_conf" {
          template = file("${path.module}/bgp_conf.tpl")
          vars = {
            cluster_name    = var.cluster_name
            service_cidr    = var.service_cidr
            asn    = var.asn
          }
        }

    resource "local_file" "bgp_conf" {
      filename = "${path.module}/bgp_conf-${var.cluster_name}.yaml"
      content  = data.template_file.bgp_conf.rendered
    }

    data "template_file" "bgp_peers" {
          template = file("${path.module}/bgp_peer.tpl")
          vars = {
            cluster_name    = var.cluster_name
            bgp_peers    = var.bgp_peers
            }
        }

    resource "local_file" "bgp_peers" {
      filename = "${path.module}/bgp_peers-${var.cluster_name}.yaml"
      content  = data.template_file.bgp_peers.rendered
    }
    resource "null_resource" "copy_files_to_bastion" {
      provisioner "local-exec" {
        command = <<-EOT
          sleep 60
          for file in ${join(" ", concat(var.copy_files_to_bastion, [local_file.kubeadm_config.filename, local_file.custom_resources.filename, local_file.bgp_conf.filename]))}; do
            echo "Copying $file to bastion"
            scp -i "my_k8s_key.pem" -o StrictHostKeyChecking=no "$file" ubuntu@${var.bastion_public_dns}:~/
          done

        EOT
      }

      depends_on = [local_file.kubeadm_config, local_file.custom_resources]
    }

    resource "null_resource" "copy_files_to_controlplane" {
      provisioner "remote-exec" {
        inline = [
          "scp -i my_k8s_key.pem -o StrictHostKeyChecking=no my_k8s_key.pem ubuntu@${var.controlplane_private_ip}:~/",
          "scp -i my_k8s_key.pem -o StrictHostKeyChecking=no kubeadm-config-${var.cluster_name}.yaml ubuntu@${var.controlplane_private_ip}:~/",
          "scp -i my_k8s_key.pem -o StrictHostKeyChecking=no custom-resources-${var.cluster_name}.yaml ubuntu@${var.controlplane_private_ip}:~/"

        ]

        connection {
          type        = "ssh"
          host        = var.bastion_public_dns
          user        = "ubuntu"
          private_key = var.private_key
        }
      }

      depends_on = [null_resource.copy_files_to_bastion, aws_instance.controlplane, null_resource.wait_for_workers_setup]
    }




    # Define the local-exec provisioner for each instance to update /etc/hosts
    resource "null_resource" "update_hosts" {
      depends_on = [
        null_resource.copy_files_to_bastion,
        aws_instance.controlplane,
        aws_instance.workers,
        null_resource.wait_for_controlplane_setup,
        null_resource.wait_for_workers_setup
      ]
    
      provisioner "local-exec" {
        command = <<-EOT
          # Generate /etc/hosts entries for all clusters
          HOSTS_ENTRIES="${join("\n", flatten([
            for cluster_name, cluster in var.cluster_details : [
              "${cluster.control_plane.ip} ${cluster.control_plane.hostname}",
              join("\n", [for worker in cluster.workers : "${worker.ip} ${worker.hostname}"])
            ]
          ]))}"
    
          # Update /etc/hosts on all nodes in the current cluster
          for ip in ${aws_instance.controlplane.private_ip} ${join(" ", aws_instance.workers[*].private_ip)}; do
            ssh -i "my_k8s_key.pem" -o StrictHostKeyChecking=no -o ProxyCommand="ssh -i my_k8s_key.pem -W %h:%p ubuntu@${var.bastion_public_dns}" ubuntu@$ip \
            "echo -e \"$HOSTS_ENTRIES\" | sudo tee -a /etc/hosts"
          done
        EOT
      }
    }












    resource "null_resource" "wait_for_workers_setup" {
      count = var.worker_count

      provisioner "remote-exec" {
        inline = [
          "while [ ! -f /home/ubuntu/setup_completed.txt ]; do echo 'Waiting for worker${count.index + 1} setup to complete...'; sleep 10; done"
        ]

        connection {
          type        = "ssh"
          host        = aws_instance.workers[count.index].private_ip
          user        = "ubuntu"
          private_key = var.private_key

          bastion_host = var.bastion_public_dns
          bastion_user = "ubuntu"
          bastion_private_key = var.private_key
        }
      }

      provisioner "local-exec" {
        command = "echo 'Worker${count.index + 1} setup complete' > ./setup_completed_worker${count.index + 1}.txt"
      }

      depends_on = [null_resource.copy_files_to_bastion, aws_instance.workers]
    }

    
    resource "null_resource" "wait_for_controlplane_setup" {
      provisioner "remote-exec" {
        inline = [
          "while [ ! -f /home/ubuntu/setup_completed.txt ]; do echo 'Waiting for setup to complete...'; sleep 10; done"
        ]
    
        connection {
          type        = "ssh"
          host        = aws_instance.controlplane.private_ip
          user        = "ubuntu"
          private_key = var.private_key

          bastion_host = var.bastion_public_dns
          bastion_user = "ubuntu"
          bastion_private_key = var.private_key
        }
      }
      provisioner "local-exec" {
        command = "echo 'Controlplane setup complete' > ./setup_completed_controlplane.txt"
      }

      depends_on = [null_resource.copy_files_to_bastion, aws_instance.controlplane]
    }

    
    resource "null_resource" "kubeadm_init" {
  provisioner "remote-exec" {
    inline = concat(
      [ # Initialize the control plane
        # "sudo kubeadm init --pod-network-cidr=${var.pod_subnet} --service-cidr=${var.service_cidr} --apiserver-advertise-address=${var.controlplane_private_ip} --apiserver-bind-port=6443 --node-name=${var.cluster_name}controlplane | tee /tmp/kubeadm_output.log",
        "sudo kubeadm init --config=kubeadm-config-${var.cluster_name}.yaml | tee /tmp/kubeadm_output.log",
        # Save kubeconfig
        "mkdir -p $HOME/.kube",
        "sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config",
        "sudo chown $(id -u):$(id -g) $HOME/.kube/config",

        # Generate the join command
        "TOKEN=$(sudo kubeadm token list | awk 'NR==2 {print $1}')",
        "CERT_HASH=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | awk '{print $2}')",
        "API_SERVER=${var.controlplane_private_ip}:6443",
        "echo \"sudo kubeadm join $API_SERVER --token $TOKEN --discovery-token-ca-cert-hash sha256:$CERT_HASH\" > /tmp/join_command.sh",

        # Apply networking
        "kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.0/manifests/tigera-operator.yaml",
        # Wait for the CRDs to be registered
        "echo 'Waiting for Calico CRDs to be registered...'",
        "until kubectl get crd installations.operator.tigera.io >/dev/null 2>&1; do echo 'Waiting for CRD...'; sleep 5; done",
        "kubectl apply -f custom-resources-${var.cluster_name}.yaml",

        # Install Calicoctl tool
        "wget https://github.com/projectcalico/calico/releases/download/v3.29.0/calicoctl-linux-amd64",
        "chmod +x ./calicoctl-linux-amd64",
        "sudo mv calicoctl-linux-amd64 /usr/local/bin/calicoctl",

        # Install k9s
        "wget https://github.com/derailed/k9s/releases/download/v0.32.7/k9s_linux_amd64.deb && sudo apt install ./k9s_linux_amd64.deb && rm k9s_linux_amd64.deb"
      ],
      [
        for worker_ip in aws_instance.workers[*].private_ip :
        "scp -i my_k8s_key.pem -o StrictHostKeyChecking=no /tmp/join_command.sh ubuntu@${worker_ip}:~/ && ssh -i my_k8s_key.pem -o StrictHostKeyChecking=no ubuntu@${worker_ip} 'chmod +x join_command.sh && sudo ./join_command.sh'"
      ]
    )

    connection {
      type                = "ssh"
      host                = var.controlplane_private_ip
      user                = "ubuntu"
      private_key         = var.private_key
      bastion_host        = var.bastion_public_dns
      bastion_user        = "ubuntu"
      bastion_private_key = var.private_key
    }
  }

  depends_on = [
    aws_instance.controlplane,
    null_resource.wait_for_controlplane_setup,
    null_resource.wait_for_workers_setup,
    null_resource.copy_files_to_controlplane,
    null_resource.update_hosts
  ]
}
