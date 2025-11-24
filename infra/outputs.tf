
# OUTPUTS

output "bastion_ip" { 
    value = aws_instance.bastion.public_ip 
}

output "jenkins_ip" { 
    value = aws_instance.jenkins.public_ip 
}

output "sonarqube_alb_dns" { 
    value = aws_lb.sonar_alb.dns_name 
}

output "nexus_alb_dns" { 
    value = aws_lb.nexus_alb.dns_name 
}


output "eks_cluster_id" { 
    value = aws_eks_cluster.eks.id 
}

output "eks_node_group_id" { 
    value = aws_eks_node_group.eks_nodes.id 
}
output "eks_cluster_endpoint" {
     value = aws_eks_cluster.eks.endpoint 
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}