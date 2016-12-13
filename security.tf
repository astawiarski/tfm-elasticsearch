resource "aws_security_group" "elasticsearch" {
  name        = "${var.cluster_name}_elasticsearch"
  description = "ElasticSearch s cluster (${var.cluster_name}) Security Group"
  vpc_id      = "${module.vpc.id}"

  tags {
    Name    = "${var.cluster_name}_elasticsearch"
    cluster = "${var.cluster_name}"
    product = "${var.tag_product}"
    purpose = "${var.tag_purpose}"
    builder = "terraform"
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "elasticsearch-in" {
  type                     = "ingress"
  from_port                = 9200
  to_port                  = 9400
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.elasticsearch.id}"

  security_group_id = "${aws_security_group.elasticsearch.id}"
}

resource "aws_security_group_rule" "allow_ssh_from_within_vpc" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["${module.vpc.cidr_block}"]

  security_group_id = "${aws_security_group.elasticsearch.id}"
}

resource "aws_security_group" "elasticsearch_elb" {
  name        = "${var.cluster_name}_elasticsearch_lb"
  description = "ElasticSearch Elastic Load Balancer Security Group"
  vpc_id      = "${module.vpc.id}"

  ingress {
    from_port   = 9200
    to_port     = 9200
    protocol    = "tcp"
    cidr_blocks = ["10.128.0.0/9"]
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    product = "${var.tag_product}"
    purpose = "${var.tag_purpose}"
    builder = "terraform"
  }
}
