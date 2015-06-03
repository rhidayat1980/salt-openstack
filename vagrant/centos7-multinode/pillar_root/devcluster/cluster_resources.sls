cluster_name: "devcluster"

cluster_type: "juno"

db_engine: "mysql"

queue_engine: "rabbit"

hosts:
  "control01": "192.168.33.21"
  "node01": "192.168.33.31"
  "node02": "192.168.33.32"
  "node03": "192.168.33.33"

roles:
  - "controller"
  - "network"
  - "storage"
  - "compute"

controller: "control01"
network: "control01"
storage:
  - "node01"
  - "node02"
  - "node03"
compute:
  - "node01"
  - "node02"
  - "node03"

sls:
  - controller:
    - "ntp"
    - "mysql"
    - "mysql.client"
    - "mysql.openstack_dbschema"
    - "queue.rabbit"
    - "keystone"
    - "keystone.openstack_tenants"
    - "keystone.openstack_users"
    - "keystone.openstack_services"
    - "glance"
    - "glance.images"
    - "nova"
    - "neutron"
    - "neutron.ml2"
    - "horizon"
    - "cinder"
    - "heat"
  - network:
    - "mysql.client"
    - "neutron.services"
    - "neutron.ml2"
    - "neutron.openvswitch"
    - "neutron.networks"
    - "neutron.routers"
    - "neutron.security_groups"
  - compute:
    - "mysql.client"
    - "nova.compute_kvm"
    - "neutron.conf"
    - "neutron.openvswitch"
    - "neutron.ml2"
  - storage:
    - "mysql.client"
    - "cinder.volume"

glance:
  images:
    "cirros":
      min_disk: "0"
      min_ram: "0"
      copy_from: "https://download.cirros-cloud.net/0.3.3/cirros-0.3.3-i386-disk.img>"
      user: "admin"
      tenant: "admin"

files:
  keystone_admin:
    path: "/root/openrc"

cinder:
  volumes_group_name: "cinder-volumes"
  volumes_path: "/var/lib/cinder/cinder-volumes"
  volumes_group_size: "1"
  loopback_device: "/dev/loop0"