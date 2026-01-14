# Security Groups
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule

# EC2 Security Group
resource "aws_security_group" "bos_ec2_sg01" {
  name        = "${local.name_prefix}-ec2-sg01"
  description = "EC2 app security group"
  vpc_id      = aws_vpc.bos_vpc01.id

  tags = {
    Name = "${local.name_prefix}-ec2-sg01"
  }
}

# RDS Security Group
resource "aws_security_group" "bos_rds_sg01" {
  name        = "${local.name_prefix}-rds-sg01"
  description = "RDS security group"
  vpc_id      = aws_vpc.bos_vpc01.id

  tags = {
    Name = "${local.name_prefix}-rds-sg01"
  }
}

# EC2 SG Rules
resource "aws_vpc_security_group_ingress_rule" "bos_ec2_http" {
  security_group_id = aws_security_group.bos_ec2_sg01.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

resource "aws_vpc_security_group_ingress_rule" "bos_ssh" {
  security_group_id = aws_security_group.bos_ec2_sg01.id
  cidr_ipv4         = "${chomp(data.http.myip.response_body)}/32"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "ec2_all_traffic_ipv4" {
  security_group_id = aws_security_group.bos_ec2_sg01.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# RDS SG Rules
resource "aws_vpc_security_group_ingress_rule" "bos_rds_mysql" {
  security_group_id            = aws_security_group.bos_rds_sg01.id
  referenced_security_group_id = aws_security_group.bos_ec2_sg01.id 

  from_port   = 3306
  to_port     = 3306
  ip_protocol = "tcp"
  description = "Allow MySQL access only from app tier EC2 instances"
}


resource "aws_vpc_security_group_egress_rule" "rds_all_traffic_ipv4" {
  security_group_id = aws_security_group.bos_rds_sg01.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # All protocols and ports
  description       = "Allow all outbound traffic"
}