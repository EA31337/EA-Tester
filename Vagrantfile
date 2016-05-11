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
Vagrant.configure(2) do |config|

  config.vm.hostname = "vagrant"
  config.vm.provision "shell", path: "scripts/provision.sh"
    # :args => '--file-ea' + opt['--file-ea'].to_s + ' --dir-bt' + opt['--dir-bt'].to_s + ' --dir-sets' + opt['--dir-sets'].to_s # @todo
  config.ssh.forward_agent = true # Enables agent forwarding over SSH connections.
  config.ssh.forward_x11 = true # Enables X11 forwarding over SSH connections.
# config.ssh.pty = true # Use pty for provisioning. Could hang the script.
  config.vm.synced_folder ".", "/vagrant", id: "core", nfs: true

  # Providers
  config.vm.provider "virtualbox" do |vm|
    vm.name = "mt-tester.local"
    vm.network "private_network", ip: "192.168.22.22"
    vm.customize ['modifyvm', :id, '--natdnshostresolver1', 'on']
    vm.memory = 4096
    vm.cpus = 2
    config.vm.box = "ubuntu/wily64"
  end

  config.vm.provider :aws do |aws, override|
    aws.aws_profile = "MT-testing"
    aws.tags = {
      'Name' => 'MT4',
    }
    aws.instance_type = "m3.medium"
    aws.ami = "ami-7747d01e"
    # aws.session_token = "SESSION TOKEN"
    # aws.instance_type = "m3.medium"
    # aws.keypair_name = "KEYPAIR NAME"

    # override.ssh.username = "ubuntu"
    # override.ssh.private_key_path = "PATH TO YOUR PRIVATE KEY"
    config.vm.box = "mt4-backtest"
  end
#
  # Plugins
  if Vagrant.has_plugin?("vagrant-timezone")
    config.timezone.value = :host
  end

end
