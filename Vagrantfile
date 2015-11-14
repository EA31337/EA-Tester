# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'getoptlong'

=begin

# @todo: http://stackoverflow.com/q/14124234/55075
# Parse optional arguments.
opts = GetoptLong.new(
  [ '--file-ea',  GetoptLong::OPTIONAL_ARGUMENT ], # EA file.
  [ '--dir-bt',   GetoptLong::OPTIONAL_ARGUMENT ], # Dir with backtest files.
  [ '--dir-sets', GetoptLong::OPTIONAL_ARGUMENT ]  # Dir with set files.
)

opts.each do |opt, arg|
  case opt
    when '--file-ea'
      file_ea==arg
    when '--dir-bt'
      dir_bt=arg
    when '--dir-sets'
      dir_sets=arg
  end
end

# @todo: When implementing above, please make sure that running of: 'vagrant -f destroy' would be supported (no invalid option error is shown).

=end

# Vagrantfile API/syntax version.
API_VERSION = "2"

Vagrant.configure(API_VERSION) do |config|

  config.vm.box = "ubuntu/vivid64"
  config.vm.network "private_network", ip: "192.168.22.22"
  config.vm.hostname = "vagrant"
  config.vm.provision "shell", path: "scripts/provision.sh"
    # :args => '--file-ea' + opt['--file-ea'].to_s + ' --dir-bt' + opt['--dir-bt'].to_s + ' --dir-sets' + opt['--dir-sets'].to_s # @todo
  config.ssh.forward_agent = true # Enables agent forwarding over SSH connections.
  config.ssh.forward_x11 = true # Enables X11 forwarding over SSH connections.
# config.ssh.pty = true # Use pty for provisioning. Could hang the script.

  config.vm.synced_folder ".", "/vagrant", id: "core",
    nfs: true

  config.vm.provider "virtualbox" do |v|
    v.customize ['modifyvm', :id, '--natdnshostresolver1', 'on']
    v.memory = 2048
    v.cpus = 2
  end

end
