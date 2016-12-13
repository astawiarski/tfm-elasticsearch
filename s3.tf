# S3
resource "aws_s3_bucket" "create_s3" {
  bucket        = "${var.cluster_name}.${var.fqdn}"
  policy        = "${data.template_file.s3_policy.rendered}"
  force_destroy = true

  tags {
    Name    = "${var.cluster_name}.${var.fqdn}"
    product = "${var.tag_product}"
    purpose = "${var.tag_purpose}"
    builder = "terraform"
  }

  versioning {
    enabled = true
  }
}

data "template_file" "s3_policy" {
  vars {
    vpc_id      = "${module.vpc.id}"
    bucket_name = "${var.cluster_name}.${var.fqdn}"
  }

  template = "${file("${path.module}/templates/s3_policy.tpl")}"
}
