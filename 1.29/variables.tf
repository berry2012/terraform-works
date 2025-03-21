variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
  default     = "automodepoc"
}


variable "region" {
  description = "AWS Region"
  type        = string
  default     = "eu-west-2"
}


variable "enable_example" {
  description = "Enable example to test this blueprint"
  type        = bool
  default     = true
}