# mapeo de zonas de disponibilidad
data "aws_availability_zones" "this" {
    state = "available"
}

# estableciendo variables locales
locals {
  aws_availability_zones = "${slice(data.aws_availability_zones.this.names, 0, length(var.cidr_pri))}"
}

data "aws_ami" "this" {
  owners = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amazon-eks-node-1.16-*",]
  }
}

locals {
  userdata = <<USERDATA
#!/bin/bash
set -o xtrace
sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
sudo systemctl start amazon-ssm-agent
sudo systemctl enable amazon-ssm-agent
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.this.endpoint}' --b64-cluster-ca '${aws_eks_cluster.this.certificate_authority.0.data}' '${aws_eks_cluster.this.id}'
USERDATA
}