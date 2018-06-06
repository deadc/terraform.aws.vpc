data "aws_availability_zones" "all" {}

resource "aws_vpc" "vpc" {
  cidr_block = "${var.base_cidr_vpc}"

  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags = "${merge(var.tags, map("Name", format("%s", var.vpc_name)))}"
}

resource "aws_subnet" "private_subnet" {
  count                   = "${var.subnet_count}"
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${cidrsubnet(var.base_cidr_vpc, var.cidr_network_bits, count.index)}"
  availability_zone       = "${element(data.aws_availability_zones.all.names, count.index)}"
  map_public_ip_on_launch = false

  tags       = "${merge(var.tags, map("Name", format("private-%s-subnet", element(data.aws_availability_zones.all.names, count.index))))}"
  depends_on = ["aws_vpc.vpc"]
}

resource "aws_subnet" "public_subnet" {
  count                   = "${var.subnet_count}"
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${cidrsubnet(var.base_cidr_vpc, var.cidr_network_bits, (count.index + var.subnet_count))}"
  availability_zone       = "${element(data.aws_availability_zones.all.names, count.index)}"
  map_public_ip_on_launch = true

  tags       = "${merge(var.tags, map("Name", format("public-%s-subnet", element(data.aws_availability_zones.all.names, count.index))))}"
  depends_on = ["aws_vpc.vpc"]
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id     = "${aws_vpc.vpc.id}"
  depends_on = ["aws_vpc.vpc"]
}

resource "aws_eip" "nat_gateway_eip" {
  vpc        = true
  depends_on = ["aws_internet_gateway.internet_gateway"]
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = "${aws_eip.nat_gateway_eip.id}"
  subnet_id     = "${aws_subnet.public_subnet.*.id[0]}"
  depends_on    = ["aws_internet_gateway.internet_gateway", "aws_subnet.public_subnet"]
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.internet_gateway.id}"
  }

  tags = "${merge(var.tags, map("Name", "route_table_public"))}"
}

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.nat_gateway.id}"
  }

  tags = "${merge(var.tags, map("Name", "route_table_private"))}"
}

resource "aws_route_table_association" "public_assoc" {
  count          = "${var.subnet_count}"
  subnet_id      = "${element(aws_subnet.public_subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "private_assoc" {
  count          = "${var.subnet_count}"
  subnet_id      = "${element(aws_subnet.private_subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.private.id}"
}

resource "aws_security_group" "vpc_security_group" {
  name   = "aws-${var.vpc_name}-vpc-sg"
  vpc_id = "${aws_vpc.vpc.id}"
}

resource "aws_security_group_rule" "ingress_allow_ssh_internal" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["${var.base_cidr_vpc}"]

  security_group_id = "${aws_security_group.vpc_security_group.id}"
}

resource "aws_security_group_rule" "egress_allow_all" {
  type        = "egress"
  from_port   = 0
  to_port     = 65535
  protocol    = "all"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.vpc_security_group.id}"
}
