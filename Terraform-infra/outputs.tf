########################################
# Public IPs
########################################

output "public_ips" {
  description = "Public IP addresses of all EC2 instances"

  value = {
    for key, instance in aws_instance.servers :
    key => instance.public_ip
  }
}

########################################
# Private IPs
########################################

output "private_ips" {
  description = "Private IP addresses of all EC2 instances"

  value = {
    for key, instance in aws_instance.servers :
    key => instance.private_ip
  }
}

########################################
# Instance IDs
########################################

output "instance_ids" {
  description = "EC2 Instance IDs"

  value = {
    for key, instance in aws_instance.servers :
    key => instance.id
  }
}

########################################
# Security Group ID
########################################

output "security_group_id" {
  value = aws_security_group.main_sg.id
}

########################################
# Key Pair Name
########################################

output "key_pair_name" {
  value = aws_key_pair.key.key_name
}

########################################
# ECR Repository URL
########################################

output "ecr_repository_url" {
  value = aws_ecr_repository.repository.repository_url
}