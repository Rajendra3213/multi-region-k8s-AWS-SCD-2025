variable "domain_name" {
  description = "Domain name for the application"
  type        = string
}

variable "primary_endpoint" {
  description = "Primary endpoint for health checks"
  type        = string
}

variable "secondary_endpoint" {
  description = "Secondary endpoint for health checks"
  type        = string
}

variable "primary_ip" {
  description = "Primary IP address"
  type        = string
}

variable "secondary_ip" {
  description = "Secondary IP address"
  type        = string
}

variable "health_check_path" {
  description = "Path for health checks"
  type        = string
  default     = "/health"
}

variable "primary_region" {
  description = "Primary AWS region"
  type        = string
}

variable "secondary_region" {
  description = "Secondary AWS region"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}