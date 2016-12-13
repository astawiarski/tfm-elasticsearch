
# AMI

[Packer](https://www.packer.io/) is used to create the AMI

# Install

Install elasticsearch with s3 ec2 and xpack plugin

# Build

To build the image using packer
```
packer build elasticsearch.json
```
# Variable

* ES URL is a link to the Elasticsearch deb package that we wanted to be 
installed
* Region: is the region where the AMI is created
* AWS AMI: is the source AMI your creation is based on

Also AWS credentials must be configured.

# Name

The AMI will be named base on the version and the time of the build following 
that pattern
simple-elasticsearch-<build_time>
Where **build_time** is the time, following that pattern *2006-01-02_15_04*, 
	  when the images is build
