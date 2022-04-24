# VPC
resource "aws_vpc" "devops_vpc" {
  cidr_block       = "172.20.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "VPC-${var.project_name}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "devops_igw" {
  vpc_id = aws_vpc.devops_vpc.id

  tags = {
    Name = "IGW-${var.project_name}"
  }
}

# Public Subnet
resource "aws_subnet" "devops_public_subnet" {
  vpc_id                  = aws_vpc.devops_vpc.id
  cidr_block              = "172.20.1.0/24"
  availability_zone       = var.availability_zone_names
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet"
  }
}

# Public Subnet for the App

resource "aws_subnet" "app_subnet" {
  vpc_id                  = aws_vpc.devops_vpc.id
  cidr_block              = "172.20.2.0/24"
  availability_zone       = var.availability_zone_names
  map_public_ip_on_launch = false

  tags = {
    Name = "app_subnet"
  }
}

# Database Public Subnet
resource "aws_subnet" "db_subnet" {
  vpc_id                  = aws_vpc.devops_vpc.id
  cidr_block              = "172.20.3.0/24"
  availability_zone       = var.availability_zone_names
  map_public_ip_on_launch = true

  tags = {
    Name = "db_subnet"
  }
}


# Route Table
resource "aws_route_table" "devops_rt" {
  vpc_id = aws_vpc.devops_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.devops_igw.id
  }

  tags = {
    Name = "public_rt-${var.project_name}"
  }
}

# Public Subnet - Route Table Association
resource "aws_route_table_association" "rt_assoc" {
  subnet_id      = aws_subnet.devops_public_subnet.id
  route_table_id = aws_route_table.devops_rt.id
}

# DB Subnet - Route Table Association
resource "aws_route_table_association" "db_rt_assoc" {
  subnet_id      = aws_subnet.db_subnet.id
  route_table_id = aws_route_table.devops_rt.id
}

# Web Access Security Group
resource "aws_security_group" "permit_web_traffic" {
  name        = "permit_web_traffic"
  description = "Permit Inbound HTTP traffic"
  vpc_id      = aws_vpc.devops_vpc.id

  ingress {
    description = "Global HTTP Access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description = "Global HTTPS Acess"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "GLobal SSH Access"
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web"
  }

}

# Microservice Security Group
resource "aws_security_group" "app_sg" {
  name        = "app_sg"
  description = "Permit inbound TCP traffic from LB"
  vpc_id      = aws_vpc.devops_vpc.id

  ingress {
    description     = "HTTP from LB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.permit_web_traffic.id]
  }

  ingress {
    description     = "UI Access from LB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.permit_web_traffic.id]

  }

  ingress {
    description     = "API Access from LB"
    from_port       = 8081
    to_port         = 8081
    protocol        = "tcp"
    security_groups = [aws_security_group.permit_web_traffic.id]

  }

  ingress {
    description = "SSH from LB"
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "microservice_access"
  }

}

# DB Security Group
resource "aws_security_group" "db_sg" {
  name        = "db_sg"
  description = "Permit microservice inbout traffic"
  vpc_id      = aws_vpc.devops_vpc.id

  ingress {
    description     = "Permit Microservice TCP Traffic"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  ingress {
    description = "Permit SSH"
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db_sg"
  }

}

# ssh public key
resource "aws_key_pair" "devops-key" {
  key_name   = "challenge_key"
  public_key = file("/home/dabdabs/challenge_keys/challenge.pub")
}


# Application EC2 Instance
resource "aws_instance" "application" {
  ami                    = var.ami_id
  key_name               = "challenge_key"
  instance_type          = var.instance_type
  availability_zone      = var.availability_zone_names
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  subnet_id              = aws_subnet.devops_public_subnet.id
  user_data              = file("ssh_conf.sh")

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file(var.aws_key_pair)
  }

  tags = {
    Name = "App_Server"
  }

}


# DB EC2 Instance
resource "aws_instance" "database" {
  ami                    = var.ami_id
  key_name               = "challenge_key"
  instance_type          = var.instance_type
  availability_zone      = var.availability_zone_names
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  subnet_id              = aws_subnet.db_subnet.id
  user_data              = file("ssh_conf.sh")

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file(var.aws_key_pair)
  }

  tags = {
    Name = "DB_Server"
  }

}


# Load Balancer EC2 Instance
resource "aws_instance" "load_balancer" {
  ami                    = var.ami_id
  key_name               = "challenge_key"
  instance_type          = var.instance_type
  availability_zone      = var.availability_zone_names
  vpc_security_group_ids = [aws_security_group.permit_web_traffic.id]
  subnet_id              = aws_subnet.devops_public_subnet.id
  user_data              = file("ssh_conf.sh")

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file(var.aws_key_pair)
  }

  tags = {
    Name = "LB_Server"
  }

}
