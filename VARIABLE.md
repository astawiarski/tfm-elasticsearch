# Input Variable

## Global
* cluster_name: Name of the cluster (must be unique per region)
* region: AWS region to setup the cluster
* azs_name: Availability zones across to setup the cluster (default:all from 
		the region)
* azs_count: Number of Availability zones you want to use for the setup.
* network_number: unique ip cluster identifier must be between 1-254,
	 	to match 10.<num>.0.0/16 CIDR

##VPC

* bastion_extra_user_data: Extra user data to use in the bastion

## ElasticSearch
* heap_size: heap size configured for the JVM
* shards: 
* number_es_node: number of desired instance in the initialisation of ASG

* es_ami: AMI for elasticsearc hinstance
* es_instance_type: Type of amazon instance use to run ElasticSearch
* elastic_extra_user_data: Extra user data to use

## Access

* key_name:amazon ssh key to use during setup of all instance


## DNS

* route_zone_id: Zone id where to create sub-domain (based on name of the 
		cluster
* fqdn: First level domain where to create sub-domain

## Curator

This is a map!
* delete_when_free_space_remaining: Minimum space which should be in the 
cluster (Lambda will delete the oldest indices until it reach this value)
* snapshot_older_days: number of days to wait before doing snapshots of indices
* execution_rate: rate of execution of the lambda (using cloudwatch format)
* bucket_path: bucket path to save the snapshot in

## TAGS

* tag_product: when setup, a product tag, with that value, is setup on all 
resources.
* tag_purpose: when setup, a purpose tag, with that value, is setup on all 
resources.
