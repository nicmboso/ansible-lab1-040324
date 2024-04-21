locals {
  name = "ansible-demo"
}

resource "aws_vpc" "vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  tags = {
    Name = "${local.name}-vpc"
  }
}

resource "aws_subnet" "public-subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.public_subnet1_cidr
  #az is better defined on the subnets than
  #on the instance to avoid conflicts
  #the instance would inherit the az defined for the subnet
  #when the subnet is defined for an instance
  availability_zone = var.az1
  tags = {
    Name = "${local.name}-public-subnet"
  }
}

#igw
#igw -to allow internet access to vpc
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${local.name}-igw"
  }
}

#eip not needed as NAT gateway is not being used
#eip is needed for NAT gateway when in use
# resource "aws_eip" "elastic-ip" {
#   domain = "vpc"
#   depends_on = [aws_internet_gateway.igw]
#   tags = {
#     Name = "${local.name}-eip"
#   }
# }

#route table
#route table-this is routing traffic to the public subnet
#via the internet gateway
resource "aws_route_table" "route_table" {
  #the route table is mapped to my vpc or
  #we can say the route table binds to my vpc
  vpc_id = aws_vpc.vpc.id
  route {
    #the cider_block is allowing all traffic to my network
    cidr_block = "0.0.0.0/0"
    #the igw is routed to my route table
    gateway_id = aws_internet_gateway.igw.id
  }
}

#rt association
resource "aws_route_table_association" "route_table_assoc" {
  #creates a route association that will bind my subnet
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.route_table.id
}

#sg
#this allows traffic only from port 22
#as ansible may not need a user interface, only
#port 22 traffic is allowed as ansible is strictly
#a command line tool
#user interface traffic may be allowed in orgs
#that use ansible tower
#so in that case sg congiguration for port 8080
#may be included
resource "aws_security_group" "security-group-1" {
  name        = "ansible-sg"
  description = "ansible_security_group"
  vpc_id      = aws_vpc.vpc.id
  #ingress allows inflow of traffic into instance
  ingress {
    description = "SSH from vpc"
    from_port   = 22
    to_port     = 22
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
    name = "${local.name}-ansible-sg"
  }
}

#sg
#to allow access from ports 22 & 80 to this instance
resource "aws_security_group" "security-group-2" {
  name        = "instance-sg"
  description = "instance_security_group"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "SSH from vpc"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "allows port 80 traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #egress is allowing all traffic
  #from this server on all ports
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    name = "${local.name}-instance-sg"
  }
}

resource "aws_key_pair" "keypair" {
  key_name   = "key-1"
  public_key = file(var.path_to_keypair)
}

resource "aws_instance" "ansible" {
  ami                         = var.ubuntu
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public-subnet.id
  key_name                    = aws_key_pair.keypair.id
  vpc_security_group_ids      = [aws_security_group.security-group-1.id]
  user_data                   = file("./userdata.sh")
  tags = {
    Name = "${local.name}-ansible"
  }
}

resource "aws_instance" "red-hat" {
  ami                         = var.red-hat
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public-subnet.id
  key_name                    = aws_key_pair.keypair.id
  vpc_security_group_ids      = [aws_security_group.security-group-2.id]
  tags = {
    Name = "${local.name}-red-hat"
  }
}

resource "aws_instance" "ubuntu" {
  ami                         = var.ubuntu
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public-subnet.id
  key_name                    = aws_key_pair.keypair.id
  vpc_security_group_ids      = [aws_security_group.security-group-2.id]
  tags = {
    Name = "${local.name}-ubuntu"
  }
}