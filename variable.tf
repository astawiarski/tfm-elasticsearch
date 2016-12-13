#global
variable "cluster_name" {
  default     = ""
  description = "Name of the cluster (must be uniq per region)"
}

variable "region" {
  default     = ""
  description = "AWS region to setup the cluster"
}

variable "network_number" {
  default     = "0"
  description = "unique ip cluster identifier must be between 1-254, to match 10.<num>.0.0/16 CIDR"
}

variable "azs_count" {
  default     = "3"
  description = "Number of Az you want the cluster to be deployed to"
}

variable "bastion_extra_user_data" {
  default     = ""
  description = "extra configuration for user data"
}

# dns related 
variable "route_zone_id" {
  default     = ""
  description = "Zone id where to create subdomain (based on name of the cluster)"
}

variable "fqdn" {
  default     = ""
  description = "First level domain where to create subdomain"
}

variable "tag_product" {
  default     = "mesos"
  description = "when setup a product tag is setup on all resources, with that value"
}

variable "tag_purpose" {
  default     = "test"
  description = "when setup a purpose tag is setup on all resources, with that value"
}

variable "heap_size" {
  default     = "8g"
  description = "heap size used for elasticsearch"
}

variable "number_es_node" {
  default     = "3"
  description = "number of elasticsearch node"
}

variable "elastic_extra_user_data" {
  default     = ""
  description = "extra user data that you can add to the launch configuration"
}

variable "key_name" {
  default     = ""
  description = "key name use for elasticsearch"
}

variable "es_ami" {
  default     = ""
  description = "ami use for elasticsearch"
}

variable "es_instance_type" {
  default     = "m4.xlarge"
  description = "instance type used for elasticsearch"
}

variable "curator" {
  default = {
    delete_when_free_space_remaining = "1T"
    snapshot_older_days              = "1"
    execution_rate                   = "1 day"
    bucket_path                      = "backups/"
  }

  descrption = ""
}
