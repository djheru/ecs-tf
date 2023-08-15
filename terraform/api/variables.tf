variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "vpc_azs" {
  type        = list(string)
  description = "A list of availability zones in the region"
  default     = ["us-east-1a", "us-east-1b"]
}

variable "private_subnets" {
  type        = list(string)
  description = "A list of private subnets in the region"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnets" {
  type        = list(string)
  description = "A list of public subnets in the region"
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "database_subnets" {
  type        = list(string)
  description = "A list of database subnets in the region"
  default     = ["10.0.201.0/24", "10.0.202.0/24"]
}

variable "app_name" {
  type    = string
  default = "polaris-api"
}

variable "app_port" {
  type    = number
  default = 4000
}

variable "cpu" {
  type    = number
  default = 256
}

variable "memory" {
  type    = number
  default = 512
}

variable "container_port" {
  type    = number
  default = 4000
}

variable "log_group_name" {
  type    = string
  default = "polaris-api-logs"
}

variable "domain_name" {
  type    = string
  default = "diversifiedmedia.cloud"
}

variable "environment_name" {
  type    = string
  default = "dev"
}

variable "cognito_user_pool_name" {
  type    = string
  default = "media-cloud-user-pool"
}

variable "iac_subnet" {
  type    = string
  default = "subnet-0ece2a8767f8070cd"
}

variable "iac_security_group" {
  type    = string
  default = "sg-0461c533906198b33"
}


