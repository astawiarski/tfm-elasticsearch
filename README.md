# tfm-elasticsearch

This Terraform module is meant to install on AWS a full Elasticsearch cluster 
from scratch.


## VPC

The VPC module is require to run this Terraform configuration


## S3 Bucket

A bucket is created with the name *<cluster-name>.<top_fqdn>*.

As the VPC module create a endpoint for S3 there will be no need to handle 
access from server within the VPC

### Policy

When creating the bucket a specific policy is created to allow access only from 
within the VPC


## ElasticSearch

### ASG

At boot the ES configuration is set with the ASG userdata, this is done to be 
able to discover based on ec2 plugin

### AWS ressource

An ELB is create and will redirect port 9200 and 80 to 9200


## Curator

A AWS lambda will be create to run Curator periodically

### AWS Lambda

The lambda is run every X time (defined with a variable) using a CloudWatch 
even and a SNS topic

### Curator python Code


All action will be done on indices older then a days.
First it will try to merge all indices then snapshots them.

Then it will delete some indices (from the older) until there is enough space 
in the cluster variable defined)
