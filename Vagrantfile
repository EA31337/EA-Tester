# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version.
API_VERSION = "2"

# Host Detection
module OS
    def OS.windows?
        (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
    end

    def OS.mac?
        (/darwin/ =~ RUBY_PLATFORM) != nil
    end

    def OS.unix?
        !OS.windows?
    end

    def OS.linux?
        OS.unix? and not OS.mac?
    end
end

Vagrant.configure(API_VERSION) do |config|

  config.vm.box = "ubuntu/vivid64"
  config.vm.box_version = "20150722.0.0"
  config.vm.network "private_network", ip: "192.168.22.22"
  config.vm.provision "shell", path: "scripts/provision.sh"
 #config.ssh.pty = true # Use pty for provisioning. Could hang the script.
  config.ssh.forward_agent = true # Enables agent forwarding over SSH connections.
  config.ssh.forward_x11 = true # Enables X11 forwarding over SSH connections.

  if OS.windows?
    config.vm.synced_folder ".", "/vagrant", id: "core",
      type: "smb",
      owner: "vagrant",
      group: "vagrant",
      mount_options: ["dir_mode=0755,file_mode=0644"]
  else
    config.vm.synced_folder ".", "/vagrant", id: "core",
      nfs: true
  end


  config.vm.provider "virtualbox" do |v|
    v.customize ['modifyvm', :id, '--natdnshostresolver1', 'on']
    v.memory = 2048
    v.cpus = 2
  end

end
