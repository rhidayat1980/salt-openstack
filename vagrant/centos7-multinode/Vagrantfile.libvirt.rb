# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  #config.vm.box = "puppetlabs-centos-7.0-64-nocm"
  config.vm.box = "uvsmtid/centos-7.0-minimal"

    config.vm.provider "libvirt" do |v|
      v.memory = 4096
      v.cpus = 2
      v.video_type = "vga"

  # Configure dhcp on eth0 on reboots:
  config.vm.provision "file", source: "configs/ifcfg-eth0", destination: "/tmp/ifcfg-eth0"

  config.vm.provision "shell", inline: "cp /tmp/ifcfg-eth0 /etc/sysconfig/network-scripts/ifcfg-eth0",
    run: "always"

  # Centos7 Disable Firewall
  config.vm.provision "shell", inline: "systemctl disable firewalld",
    run: "always"
  config.vm.provision "shell", inline: "systemctl stop firewalld",
    run: "always"
  end

  # Options for libvirt vagrant provider.
  config.vm.provider :libvirt do |libvirt|

    # A hypervisor name to access. Different drivers can be specified, but
    # this version of provider creates KVM machines only. Some examples of
    # drivers are kvm (qemu hardware accelerated), qemu (qemu emulated),
    # xen (Xen hypervisor), lxc (Linux Containers),
    # esx (VMware ESX), vmwarews (VMware Workstation) and more. Refer to
    # documentation for available drivers (http://libvirt.org/drivers.html).
    libvirt.driver = "kvm"

    # IMPORTANT support netsted virtualization:
    libvirt.nested = "True"

    # CPU Mode What cpu mode to use for nested virtualization. Defaults to 'host-model' if not set.
    #libvirt.cpu_mode = ""

    # The name of the server, where libvirtd is running.
    #libvirt.host = "localhost"

    # Localhost change uri:
    libvirt.uri = 'qemu+unix:///system'

    # If use ssh tunnel to connect to Libvirt.
    libvirt.connect_via_ssh = false

    # The username and password to access Libvirt. Password is not used when
    # connecting via ssh.
    #libvirt.username = "user"
    #libvirt.password = "secret"

    # Libvirt storage pool name, where box image and instance snapshots will
    # be stored.
    libvirt.storage_pool_name = "default"

    # Set a prefix for the machines that's different than the project dir name.
    #libvirt.default_prefix = ''
  end

  config.vm.define "master" do |node|

    node.vm.hostname = "master"

    # Openstack Network for Admin/Public/Mgmt
    node.vm.network :private_network, type: "static", ip: "192.168.33.10",
      libvirt__network_name: "salt-os-public",
      libvirt__netmask: "255.255.255.0",
      libvirt__dhcp_enabled: true

    # Openstack Flat Network for openstack
    # no dhcp needed here from vagrant, dhcp via Openstack
    # the ip info here is a dummy config so Vagrant doesn't complain.
    node.vm.network :private_network, ip: "192.168.36.10",
      libvirt__network_name: "salt-os-flat",
      libvirt__netmask: "255.255.255.0",
      libvirt__dhcp_enabled: false,
      auto_config: false

    # Configure SALT info from local gitrepo:
    node.vm.synced_folder "../../file_root/", "/srv/salt", type: "rsync"
    node.vm.synced_folder "pillar_root/", "/srv/pillar", type: "rsync"

    # Configure minion_id identifier
    # node.vm.provision "shell", inline: "echo 'master' > /etc/salt/minion_id"

    # Fix vagrant libvirt dhcp network issue:
    #node.vm.provision "shell", inline: "ip addr flush eth1 && ifup eth1"

    # salt-master provisioning
    node.vm.provision :salt do |salt|
      salt.install_master = true
      salt.always_install = true
      salt.master_config = "configs/master"
      salt.run_highstate = false
      salt.master_key = 'keys/master.pem'
      salt.master_pub = 'keys/master.pub'

      salt.minion_config = "configs/minion"
      salt.minion_key = 'keys/master.pem'
      salt.minion_pub = 'keys/master.pub'

      salt.seed_master = {
        'master' => 'keys/master.pub',
        'control01' => 'keys/control01.pub',
        'node01' => 'keys/node01.pub',
        'node02' => 'keys/node02.pub',
        'node03' => 'keys/node03.pub'
      }
    end
  end

  ## CONTROLLER ##
  config.vm.define "control01" do |node|
    node.vm.hostname = "control01"

    # Openstack Network for Admin/Public/Mgmt
    node.vm.network :private_network, ip: "192.168.33.21",
      libvirt__network_name: "salt-os-public"

    # Openstack Flat Network for openstack
    # no dhcp needed here from vagrant, dhcp via Openstack
    # the ip info here is a dummy config so Vagrant doesn't complain.
    node.vm.network :private_network, ip: "192.168.36.21",
      libvirt__network_name: "salt-os-flat",
      libvirt__netmask: "255.255.255.0",
      libvirt__dhcp_enabled: false,
      auto_config: false


    # Configure minion_id identifier if using a salted image:
    #node.vm.provision "shell", inline: "echo 'control01' > /etc/salt/minion_id"

    # Fix vagrant libvirt dhcp network issue:
    node.vm.provision "shell", inline: "ip addr flush eth1 && ifup eth1"
    node.vm.provision "shell", inline: "ip addr flush eth2"

    # salt-minion provisioning
    node.vm.provision :salt do |salt|
      salt.minion_config = "configs/minion"
      salt.minion_key = 'keys/control01.pem'
      salt.minion_pub = 'keys/control01.pub'
      salt.run_highstate = true
    end
  end

  ## NODES ##
  config.vm.define "node01" do |node|
    node.vm.hostname = "node01"

    # Openstack Network for Admin/Public/Mgmt
    node.vm.network :private_network, ip: "192.168.33.31"

    # Openstack Flat Network for openstack
    # no dhcp needed here from vagrant, dhcp via Openstack
    # the ip info here is a dummy config so Vagrant doesn't complain.
    node.vm.network :private_network, ip: "192.168.36.31",
      libvirt__network_name: "salt-os-flat",
      libvirt__netmask: "255.255.255.0",
      libvirt__dhcp_enabled: false,
      auto_config: false

    # Configure minion_id identifier
    #node.vm.provision "shell", inline: "echo '#{node.vm.hostname}' > /etc/salt/minion_id"

    # Fix vagrant libvirt dhcp network issue:
    #node.vm.provision "shell", inline: "ip addr flush eth1 && ifup eth1"
    #node.vm.provision "shell", inline: "ip addr flush eth2"

    # Configure extra drives, assume they all exist if the first one is present:
    # Add 3 additional 4GB drives
    config.vm.provider :libvirt do |libvirt|
      libvirt.memory = 4096
      libvirt.storage :file, :size => '4G'
      libvirt.storage :file, :size => '4G'
      libvirt.storage :file, :size => '4G'
    end

    # salt-minion provisioning
    node.vm.provision :salt do |salt|
      salt.minion_config = "configs/minion"
      salt.minion_key = "keys/#{node.vm.hostname}.pem"
      salt.minion_pub = "keys/#{node.vm.hostname}.pub"
    end
  end

  config.vm.define "node02" do |node|
    node.vm.hostname = "node02"

    # Openstack Network for Admin/Public/Mgmt
    node.vm.network :private_network, ip: "192.168.33.32"

    # Openstack Flat Network for openstack
    # no dhcp needed here from vagrant, dhcp via Openstack
    # the ip info here is a dummy config so Vagrant doesn't complain.
    node.vm.network :private_network, ip: "192.168.36.32",
      libvirt__network_name: "salt-os-flat",
      libvirt__netmask: "255.255.255.0",
      libvirt__dhcp_enabled: false,
      auto_config: false

    # Configure minion_id identifier
    #node.vm.provision "shell", inline: "echo '#{node.vm.hostname}' > /etc/salt/minion_id"

    # Fix vagrant libvirt dhcp network issue:
    #node.vm.provision "shell", inline: "ip addr flush eth1 && ifup eth1"
    #node.vm.provision "shell", inline: "ip addr flush eth2"

    # Configure extra drives, assume they all exist if the first one is present:
    # Add 3 additional 4GB drives
    config.vm.provider :libvirt do |libvirt|
      libvirt.storage :file, :size => '4G'
      libvirt.storage :file, :size => '4G'
      libvirt.storage :file, :size => '4G'
    end

    # salt-minion provisioning
    node.vm.provision :salt do |salt|
      salt.minion_config = "configs/minion"
      salt.minion_key = "keys/#{node.vm.hostname}.pem"
      salt.minion_pub = "keys/#{node.vm.hostname}.pub"
    end
  end

  config.vm.define "node03" do |node|
    node.vm.hostname = "node03"

    # Openstack Network for Admin/Public/Mgmt
    node.vm.network :private_network, ip: "192.168.33.33"

    # Openstack Flat Network for openstack
    # no dhcp needed here from vagrant, dhcp via Openstack
    # the ip info here is a dummy config so Vagrant doesn't complain.
    node.vm.network :private_network, ip: "192.168.36.33",
      libvirt__network_name: "salt-os-flat",
      libvirt__netmask: "255.255.255.0",
      libvirt__dhcp_enabled: false,
      auto_config: false

    # Configure minion_id identifier
    #node.vm.provision "shell", inline: "echo '#{node.vm.hostname}' > /etc/salt/minion_id"

    # Fix vagrant libvirt dhcp network issue:
    #node.vm.provision "shell", inline: "ip addr flush eth1 && ifup eth1"
    #node.vm.provision "shell", inline: "ip addr flush eth2"

    # Configure extra drives, assume they all exist if the first one is present:
    # Add 3 additional 4GB drives
    config.vm.provider :libvirt do |libvirt|
      libvirt.storage :file, :size => '4G'
      libvirt.storage :file, :size => '4G'
      libvirt.storage :file, :size => '4G'
    end

    # salt-minion provisioning
    node.vm.provision :salt do |salt|
      salt.minion_config = "configs/minion"
      salt.minion_key = "keys/#{node.vm.hostname}.pem"
      salt.minion_pub = "keys/#{node.vm.hostname}.pub"
    end
  end

end
