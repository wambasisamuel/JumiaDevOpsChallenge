# Project Name
variable "project_name" {
  description = "Project Name"
  type        = string
  default     = "DevOps_Challenge"

}

variable "availability_zone_names" {
  type    = string
  default = "eu-west-3a"
}

# Instance variables
variable "ami_id" {
  description = "EC2 Instance AMI"
  type        = string
  default     = "ami-0c6ebbd55ab05f070"
}

variable "instance_type" {
  description = "EC2 Instance Type"
  type        = string
  default     = "t2.micro"
}

#AWS Key
variable "aws_key_pair" {
  default = "/home/dabdabs/challenge_keys/challenge_key.pem"
}
