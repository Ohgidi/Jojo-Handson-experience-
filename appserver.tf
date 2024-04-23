resource "aws_instance" "web_server" {
  ami                    = "ami-0c618421e207909d0"
  instance_type          = "t2.micro"
  key_name               = data.aws_key_pair.Demo-ohg.key_name
  vpc_security_group_ids = [aws_security_group.DemoSG.id]
  subnet_id              = aws_subnet.public-subnet.id


  tags = {
    Name = "OhgDemo"
  }
}

data "aws_key_pair" "Demo-ohg" {
  key_name           = "Demo-ohg"
  include_public_key = true
}


resource "aws_security_group" "DemoSG" {
  name        = "DevopsSG"
  description = "Allow only SSH acess from my IP"
  vpc_id      = aws_vpc.Devopsvpc.id

  ingress {
    protocol    = "tcp"
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    description = "SSH"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc" "Devopsvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
}

resource "aws_subnet" "private-subnet" {
  vpc_id            = aws_vpc.Devopsvpc.id
  availability_zone = "eu-west-2a"
  cidr_block        = "10.0.1.0/24"

}

resource "aws_subnet" "public-subnet" {
  vpc_id            = aws_vpc.Devopsvpc.id
  availability_zone = "eu-west-2b"
  cidr_block        = "10.0.2.0/24"
}


resource "aws_internet_gateway" "DemoGW" {
  vpc_id = aws_vpc.Devopsvpc.id

}

resource "aws_route_table" "DemoRT" {
  vpc_id = aws_vpc.Devopsvpc.id

  route {
    cidr_block = "0.0.0.0/16"
    gateway_id = aws_internet_gateway.DemoGW.id
  }
}

# resource "aws_route_table_association" "DemoRTA" {
#   subnet_id = "aws_subnet.demosng.id"
#   route_table_id = aws_route_table.DemoRT.id
# }


# resource "aws_route_table_association" "DemoRTB" {
#   gateway_id = aws_internet_gateway.DemoGW.id
#   route_table_id = aws_route_table.DemoRT.id
# }

resource "aws_db_parameter_group" "demodb" {
  name   = "rds-pg"
  family = "mysql5.7"

}

resource "aws_db_subnet_group" "demosng" {
  name       = "demosng"
  subnet_ids = [aws_subnet.private-subnet.id, aws_subnet.public-subnet.id]
}

resource "aws_db_instance" "demodbs" {
  allocated_storage      = 20
  db_name                = "demodbs"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t3.micro"
  username               = "demo"
  password               = "demopass"
  db_subnet_group_name   = aws_db_subnet_group.demosng.id
  vpc_security_group_ids = [aws_security_group.DemoSG.id]
  parameter_group_name   = aws_db_parameter_group.demodb.name
  skip_final_snapshot    = true
  multi_az               =  false
}