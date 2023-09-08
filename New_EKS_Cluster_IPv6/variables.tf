variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
  default     = "ipv6-tf"
}


variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-2"
}


variable "enable_example" {
  description = "Enable example to test this blueprint"
  type        = bool
  default     = true
}