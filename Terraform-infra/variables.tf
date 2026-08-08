variable "aws_region" {
  type = string
}

variable "my_ip" {
  type = string
}

variable "key_pair_name" {
  type = string
}

variable "public_key_path" {
  type = string
}

variable "instance_types" {
  description = "Map of EC2 instance types per role, keyed the same as instance_names"
  type        = map(string)
  default = {
    jenkins = "c7i-flex.large"
    master  = "c7i-flex.large"
    worker1 = "m7i-flex.large"
    worker2 = "m7i-flex.large"
  }
}

variable "root_volume_size" {
  type    = number
  default = 30
}

variable "ami_id" {
  type = string
}

variable "instance_names" {
  description = "Map of EC2 instance names"
  type        = map(string)
}
variable "ecr_repository_name" {
  type = string
}