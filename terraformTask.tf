provider "aws" {
  region = "ap-south-1"
  profile = "pintu"
}


resource "aws_vpc" "AjVpc" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"

  tags = {
    Name = "AjVpc"
  }
}


resource "aws_subnet" "Ajsubnet-1a" {
  vpc_id     = aws_vpc.AjVpc.id
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = "true"
  depends_on = [
    aws_vpc.AjVpc,
  ]

  tags = {
    Name = "Ajsubnet-1a"
  }
}


resource "aws_subnet" "Ajsubnet-1b" {
  vpc_id     = aws_vpc.AjVpc.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1b"
  depends_on = [
    aws_vpc.AjVpc,
  ]

  tags = {
    Name = "Ajsubnet-1b"
  }
}



resource "aws_internet_gateway" "Ajigw" {
  vpc_id = aws_vpc.AjVpc.id
  depends_on = [
    aws_vpc.AjVpc,
  ]

  tags = {
    Name = "Ajigw"
  }
}


resource "aws_route_table" "route-1a" {
  vpc_id = aws_vpc.AjVpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Ajigw.id
  }
  
  depends_on = [
    aws_vpc.AjVpc,
  ]

  tags = {
    Name = "route-1a"
  }
}


resource "aws_route_table_association" "associate-1a" {
  subnet_id      = aws_subnet.Ajsubnet-1a.id
  route_table_id = aws_route_table.route-1a.id

  depends_on = [
    aws_subnet.Ajsubnet-1a,
  ]
}


resource "aws_security_group" "wordpress-sgroup" {
  name        = "wordpress-sgroup"
  description = "allows ssh and http"
  vpc_id      = aws_vpc.AjVpc.id

  ingress {
    description = "for SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "for HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  depends_on = [
    aws_vpc.AjVpc,
  ]

  tags = {
    Name = "wordpress-sgroup"
  }
}




resource "aws_security_group" "Mysql-sgroup" {
  name        = "Mysql-sgroup"
  description = "allows wordpress security group"
  vpc_id      = aws_vpc.AjVpc.id

  ingress {
    description = "for wordpress security group"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.wordpress-sgroup.id]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }  

  depends_on = [
    aws_vpc.AjVpc,
    aws_security_group.wordpress-sgroup,
  ]

  tags = {
    Name = "Mysql-sgroup"
  }
}




resource "aws_instance" wordpress {
  ami = "ami-7e257211"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.Ajsubnet-1a.id
  key_name = "ekskey11"
  vpc_security_group_ids = [aws_security_group.wordpress-sgroup.id]

  depends_on = [
    aws_subnet.Ajsubnet-1a,
    aws_security_group.wordpress-sgroup,
  ]

  tags = {
    Name = "wordpress"
  }
}




resource "aws_instance" Mysql {
  ami = "ami-76166b19"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.Ajsubnet-1b.id
  key_name = "ekskey11"
  vpc_security_group_ids = [aws_security_group.Mysql-sgroup.id]

  depends_on = [
    aws_subnet.Ajsubnet-1b,
    aws_security_group.Mysql-sgroup,
  ]

  tags = {
    Name = "Mysql"
  }
}



output "Ip_of_wordpress" {
  value = aws_instance.wordpress.public_ip
}

output "Id_of_wordpress_instance" {
  value = aws_instance.wordpress.id
}