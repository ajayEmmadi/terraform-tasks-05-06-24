#defining CIDR block for Vpc
variable "vpc_cidr" {
    default = "10.0.0.0/16"
}

variable "subnet_cidr" {
default = "10.0.1.0/24"
}