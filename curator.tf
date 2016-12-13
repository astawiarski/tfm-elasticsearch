resource "null_resource" "build-curator-lambda" {
  provisioner "local-exec" "build lambda" {
    command = "cd ${path.module}/curator_clean/ && make all" # Changes to any instance of the cluster requires re-provisioning
  }
}

# scheduling
resource "aws_cloudwatch_event_rule" "scheduler-curator" {
  name                = "${var.cluster_name}_scheduler_lambda-curator"
  schedule_expression = "rate(${var.curator["execution_rate"]})"
}

resource "aws_cloudwatch_event_target" "scheduler-curator" {
  rule      = "${aws_cloudwatch_event_rule.scheduler-curator.name}"
  target_id = "${var.cluster_name}_SendToLambda-scheduler_node"
  arn       = "${aws_lambda_function.curator.arn}"

  input = <<EOF
{ 
  "es_endpoint": "${aws_elb.elasticsearch.dns_name}:9200",
  "repository": "${var.cluster_name}-bucket",
  "backup_bucket": "${aws_s3_bucket.create_s3.id}",
  "backup_path": "${var.curator["bucket_path"]}",
  "delete_when_free_space_remaining":"${var.curator["delete_when_free_space_remaining"]}",
  "snapshot_older_days":"${var.curator["snapshot_older_days"]}"
}
EOF
}

resource "aws_lambda_permission" "scheduler-curator" {
  statement_id  = "${var.cluster_name}_curator_scheduler"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.curator.arn}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.scheduler-curator.arn}"
}

#  curator
resource "aws_iam_role_policy" "curator" {
  name = "${var.cluster_name}_curator"
  role = "${aws_iam_role.curator.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
	{
	"Effect": "Allow",
	"Action": [
		"logs:CreateLogGroup",
		"logs:CreateLogStream",
		"logs:PutLogEvents"
	],
	"Resource": "arn:aws:logs:*:*:*"
	},
	{
	"Effect": "Allow",
	"Action": [
		"ec2:CreateNetworkInterface",
		"ec2:DescribeNetworkInterfaces",
		"ec2:DeleteNetworkInterface"
	],
	"Resource": "*"
	}
  ]
}
EOF
}

resource "aws_iam_role" "curator" {
  name = "${var.cluster_name}_curator"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
	{
	  "Action": "sts:AssumeRole",
	  "Principal": {
		"Service": "lambda.amazonaws.com"
	  },
	  "Effect": "Allow",
	  "Sid": ""
	}
  ]
}
EOF
}

resource "aws_lambda_function" "curator" {
  filename      = "${path.module}/curator_clean/build/lambda-curator_clean.zip"
  function_name = "${var.cluster_name}_curator"
  role          = "${aws_iam_role.curator.arn}"
  handler       = "curator_clean.lambda_handler"
  runtime       = "python2.7"
  timeout       = 300

  vpc_config {
    subnet_ids         = ["${split(",",module.vpc.subnets_private)}"]
    security_group_ids = ["${aws_security_group.elasticsearch.id}"]
  }

  depends_on = ["null_resource.build-curator-lambda", "aws_iam_role_policy.curator"]
}
