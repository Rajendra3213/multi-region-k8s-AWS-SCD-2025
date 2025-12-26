variable "accelerator_name" {
  description = "Name of the Global Accelerator"
  type        = string
}

variable "primary_region" {
  description = "Primary AWS region"
  type        = string
}

variable "secondary_region" {
  description = "Secondary AWS region"
  type        = string
}

variable "primary_nlb_arn" {
  description = "ARN of the primary Network Load Balancer"
  type        = string
}

variable "secondary_nlb_arn" {
  description = "ARN of the secondary Network Load Balancer"
  type        = string
}

variable "health_check_path" {
  description = "Path for health checks"
  type        = string
  default     = "/health"
}

variable "flow_logs_enabled" {
  description = "Enable flow logs"
  type        = bool
  default     = false
}

variable "flow_logs_s3_bucket" {
  description = "S3 bucket for flow logs"
  type        = string
  default     = ""
}

variable "flow_logs_s3_prefix" {
  description = "S3 prefix for flow logs"
  type        = string
  default     = "flow-logs/"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}