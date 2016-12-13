resource "aws_elb" "elasticsearch" {
  name                      = "${var.cluster_name}-elasticsearch"
  security_groups           = ["${aws_security_group.elasticsearch_elb.id}", "${module.vpc.sg_bastion}", "${aws_security_group.elasticsearch.id}"]
  subnets                   = ["${split(",",module.vpc.subnets_private)}"]
  cross_zone_load_balancing = true
  connection_draining       = true
  internal                  = true
  idle_timeout              = 3600

  listener {
    instance_port     = 9200
    instance_protocol = "HTTP"
    lb_port           = 9200
    lb_protocol       = "HTTP"
  }

  listener {
    instance_port     = 9200
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
    target              = "HTTP:9200/_cluster/health"
    timeout             = 5
  }

  tags {
    product = "${var.tag_product}"
    purpose = "${var.tag_purpose}"
    builder = "terraform"
  }
}

resource "aws_autoscaling_group" "elasticsearch_autoscale_group" {
  name                      = "${var.cluster_name}_elasticsearch"
  vpc_zone_identifier       = ["${split(",",module.vpc.subnets_private)}"]
  launch_configuration      = "${aws_launch_configuration.elasticsearch_launch_config.id}"
  min_size                  = 3
  max_size                  = 12
  desired_capacity          = "${var.number_es_node}"
  health_check_grace_period = "900"
  health_check_type         = "EC2"
  load_balancers            = ["${aws_elb.elasticsearch.name}"]

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}_elasticsearch"
    propagate_at_launch = true
  }

  tag {
    key                 = "purpose"
    value               = "${var.tag_purpose}"
    propagate_at_launch = true
  }

  tag {
    key                 = "product"
    value               = "${var.tag_product}"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "elasticsearch_launch_config" {
  name_prefix          = "${var.cluster_name}_elasticsearch_"
  image_id             = "${var.es_ami}"
  instance_type        = "${var.es_instance_type}"
  iam_instance_profile = "${aws_iam_instance_profile.elasticsearch.name}"
  key_name             = "${var.key_name}"
  security_groups      = ["${aws_security_group.elasticsearch.id}"]
  enable_monitoring    = false
  user_data            = "${data.template_file.launch_elasticsearch.rendered}"

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_size = "2096" #${var.elasticsearch_volume_size}"
    volume_type = "gp2"
  }
}

data "template_file" "launch_elasticsearch" {
  vars {
    cluster_name       = "${var.cluster_name}"
    fqdn               = "${var.fqdn}"
    region             = "${var.region}"
    security_groups    = "${aws_security_group.elasticsearch.name}"
    availability_zones = "${module.vpc.azs}"
    heap_size          = "${var.heap_size}"
  }

  template = "${file("${path.module}/templates/elasticsearch.tpl")}\n${var.elastic_extra_user_data}"
}
