resource "aws_iam_role" "elasticsearch" {
  name = "${var.cluster_name}_elasticsearch"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
	{
	  "Action": "sts:AssumeRole",
	  "Principal": {
		"Service": "ec2.amazonaws.com"
	  },
	  "Effect": "Allow",
	  "Sid": ""
	}
  ]
}
EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_instance_profile" "elasticsearch" {
  name  = "${var.cluster_name}_elasticsearch"
  roles = ["${aws_iam_role.elasticsearch.name}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "elasticsearch" {
  name = "${var.cluster_name}_elasticsearch"
  role = "${aws_iam_role.elasticsearch.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
	{
	  "Effect": "Allow",
	  "Action": [
		"ec2:DescribeInstances",
		"autoscaling:DescribeAutoScalingGroups"
	  ],
	  "Resource": "*"
	},
	{
	  "Action": [
		"s3:ListBucket",
		"s3:GetBucketLocation",
		"s3:ListBucketMultipartUploads",
		"s3:ListBucketVersions"
	  ],
	  "Effect": "Allow",
	  "Resource": [
		"arn:aws:s3:::${aws_s3_bucket.create_s3.id}"

	  ]
	},
	{
	  "Action": [
		"s3:GetObject",
		"s3:PutObject",
		"s3:AbortMultipartUpload",
		"s3:ListMultipartUploadParts"
	  ],
	  "Effect": "Allow",
	  "Resource": [
		"arn:aws:s3:::${aws_s3_bucket.create_s3.id}/*"
	  ]
	}
  ]
}
EOF

  lifecycle {
    create_before_destroy = true
  }
}
