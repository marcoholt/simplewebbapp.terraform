variable "project" {
  type    = string
  default = "simplewebapp"
}

variable "region" {
  type    = string
  default = "us-east-2"
}

variable "domain_name" {
  type    = string
  default = ""
  # OPTION A: Optional - not used with ALB DNS
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "az_count" {
  type    = number
  default = 2
}

variable "eks_min_size" {
  type    = number
  default = 2
}

variable "eks_max_size" {
  type    = number
  default = 4
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_username" {
  type    = string
  default = "appuser"
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}