variable "namespace" {
  type        = string
  description = "Namespace for resource naming."
  default     = "luscii"
}

variable "environment" {
  type        = string
  description = "Environment name."
  default     = "dev"
}

variable "name" {
  type        = string
  description = "Name for the label and resources."
  default     = "dotnet-app"
}

variable "dotnet_container" {
  type        = string
  description = "Name of the .NET container in ECS."
  default     = "dotnet-app"
}
