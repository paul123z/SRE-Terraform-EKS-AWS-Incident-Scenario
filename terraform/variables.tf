variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"  # Frankfurt region
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "sre-incident-demo"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b"]  # Frankfurt AZs
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "sre-incident-demo"
    Environment = "demo"
    Owner       = "devops"
    Purpose     = "learning"
  }
} 