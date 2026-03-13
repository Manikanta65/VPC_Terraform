variable "project" {
    type = string
    default = "roboshop"
}

variable "environment" {
    type = string
    default = "Dev"
}

variable "igw_tags" {
    type = map
    default = {}
}

variable "vpc_tags" {
    type = map
    default = {}
}
 