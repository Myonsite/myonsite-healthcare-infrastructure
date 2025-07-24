variable "aws_region" {
  description = "AWS region to deploy EKS cluster"
  type        = string
  default     = "us-east-1"
  
  validation {
    condition = contains([
      "us-east-1", "us-east-2", "us-west-1", "us-west-2",
      "eu-west-1", "eu-west-2", "eu-central-1", "ap-southeast-1"
    ], var.aws_region)
    error_message = "AWS region must be a valid region."
  }
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "medinovai-prod"
  
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.cluster_name))
    error_message = "Cluster name must start with a letter and contain only alphanumeric characters and hyphens."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the EKS cluster API server"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Restrict this in production
  
  validation {
    condition = alltrue([
      for cidr in var.allowed_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All CIDR blocks must be valid IPv4 CIDR notation."
  }
}

variable "node_groups_config" {
  description = "Configuration for EKS node groups"
  type = object({
    general = object({
      min_size         = number
      max_size         = number
      desired_size     = number
      instance_types   = list(string)
    })
    spot = object({
      min_size         = number
      max_size         = number
      desired_size     = number
      instance_types   = list(string)
    })
    infrastructure = object({
      min_size         = number
      max_size         = number
      desired_size     = number
      instance_types   = list(string)
    })
  })
  
  default = {
    general = {
      min_size       = 2
      max_size       = 10
      desired_size   = 3
      instance_types = ["c7g.large", "c7g.xlarge"]
    }
    spot = {
      min_size       = 0
      max_size       = 10
      desired_size   = 2
      instance_types = ["c7g.large", "c7g.xlarge", "m7g.large"]
    }
    infrastructure = {
      min_size       = 1
      max_size       = 3
      desired_size   = 1
      instance_types = ["c7g.large"]
    }
  }
} 