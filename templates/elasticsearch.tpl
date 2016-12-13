#!/bin/bash -v

cat <<EOF >/etc/default/elasticsearch
ES_JAVA_OPTS="-Xms${heap_size} -Xmx${heap_size}"
EOF

cat <<EOF >/etc/elasticsearch/elasticsearch.yml

cluster:
  name: ${cluster_name}
  routing.allocation.awareness.attributes: aws_availability_zone

node.name: $${HOSTNAME}

bootstrap.memory_lock: true

http.compression: true
transport.tcp.compress: true

network:
  host: 0.0.0.0
  tcp.keep_alive: true


cloud:
  aws.region: ${region}
  node.auto_attributes: true

discovery:
  type: ec2
  ec2:
    groups: ${security_groups}
    availability_zones: ${availability_zones}
  zen:
# yes, this is used even when the type is ec2
    fd:
      ping_retries: 10
      ping_interval: 15s

repositories:
    s3:
        bucket: ${cluster_name}.${fqdn}
        base_path: /backups/
        chunk_size: 50m

xpack.security.enabled: false
xpack.security.authc.anonymous.roles: logs
xpack.security.authc.anonymous.authz_exception: false 

EOF

sed -i 's/logstash/logs/' /etc/elasticsearch/x-pack/roles.yml

systemctl restart elasticsearch

