output "elb_dns" {
  value = "${aws_elb.elasticsearch.dns_name}"
}
