resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = local.vpc_final_tags
}

##################################### Creating internet-gateway and attaching to VPC  #############################################################

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = local.igw_final_tags
}

#################################### Create subnets for Public, Private and Database #############################################################

resource "aws_subnet" "public_subnets" {
  for_each = {
    "us-east-1a" = "10.0.1.0/24"
    "us-east-1b" = "10.0.2.0/24"
  }
    vpc_id            = aws_vpc.main.id
    cidr_block        = each.value
    availability_zone = each.key
    tags = {
    Name = "${var.project}-${var.environment}-public-${each.key}"  #roboshop-dev-
  }
}

resource "aws_subnet" "private_subnets" {
  for_each = {
    "us-east-1a" = "10.0.11.0/24"
    "us-east-1b" = "10.0.12.0/24"
  }
    vpc_id            = aws_vpc.main.id
    cidr_block        = each.value
    availability_zone = each.key
    tags = {
    Name = "${var.project}-${var.environment}-private-${each.key}"  #roboshop-dev-
   }
}

resource "aws_subnet" "database_subnets" {
  for_each = {
    "us-east-1a" = "10.0.21.0/24"
    "us-east-1b" = "10.0.22.0/24"
  }
 vpc_id            = aws_vpc.main.id
    cidr_block        = each.value
    availability_zone = each.key
    tags = {
    Name = "${var.project}-${var.environment}-database-${each.key}"   #roboshop-dev-
   }
}

#################################### Created Routbale for Public and did association of public subnets #############################################################

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "${var.project}-${var.environment}-public"
  }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public_subnets

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

####################################  Creating Elastci Ip and NAT gateway #############################################################

resource "aws_eip" "nat" {
  domain     = "vpc"
  tags = {
    Name = "${var.project}-${var.environment}-nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnets["us-east-1a"].id
  tags = {
    Name = "${var.project}-${var.environment}-nat-gw"
  }
}

###################### Creating Private route table with NAT gateway and with association of private subnets #############################################################

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

   route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${var.project}-${var.environment}-private"
  }
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private_subnets

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

###################### Creating Private route table with NAT gateway and with association of database subnets #############################################################


resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

 route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${var.project}-${var.environment}-database"
  }
}

resource "aws_route_table_association" "database" {
  for_each = aws_subnet.database_subnets

  subnet_id      = each.value.id
  route_table_id = aws_route_table.database.id
}



