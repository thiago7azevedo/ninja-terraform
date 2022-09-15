variable "env" {
  type        = string
  description = "name of the env"
}

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR block for VPC"
}

variable "public_subnet_cidr_blocks" {
  type        = list(string)
  description = "CIDR block for public subnet"
}

variable "release_version" {
  type = string
  description = "Image version which needs to be deployed"
  default = ""
}

variable "image" {
  type = string
  description = "Repository with image"
  default = "thiago7azeveo/devops-ninja"
}