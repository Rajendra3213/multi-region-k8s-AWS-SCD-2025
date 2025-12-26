variable "name" {
  description = "Name of the Transit Gateway"
  type        = string
}

variable "description" {
  description = "Description of the Transit Gateway"
  type        = string
  default     = "Multi-region EKS Transit Gateway"
}

variable "vpc_attachments" {
  description = "Map of VPC attachments"
  type = map(object({
    vpc_id     = string
    subnet_ids = list(string)
  }))
  default = {}
}

variable "routes" {
  description = "Map of routes to create"
  type = map(object({
    destination_cidr_block = string
    attachment_key         = string
  }))
  default = {}
}

variable "vpc_routes" {
  description = "Map of VPC routes to create"
  type = map(object({
    route_table_id         = string
    destination_cidr_block = string
  }))
  default = {}
}

variable "create_route_table" {
  description = "Whether to create a custom route table"
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}