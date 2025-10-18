variable "public_key" {
  description = "Public SSH key for EC2 access"
  type        = string
  default     = ""
}

variable "aws_access_key" {
  description = "AWS Access Key"
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS Secret Key"
  type        = string
  default     = ""
  sensitive   = true
}
