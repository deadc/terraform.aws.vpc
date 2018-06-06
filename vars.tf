variable "vpc_name" {
  description = "VPC name"
  default     = "enterprise-vpc"
}

variable "base_cidr_vpc" {
  description = "Base cidr for generate the subnets"
  default     = "10.10.0.0/16"
}

variable "cidr_network_bits" {
  description = "The network bits for subnets"
  default     = "8"
}

variable "subnet_count" {
  description = "The number of subnets"
  default     = "2"
}

variable "tags" {
  description = "A map of tags to resources"
  default     = {}
}
