# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'getoptlong'

# Parse CLI arguments.
opts = GetoptLong.new(
  [ '--provider', GetoptLong::OPTIONAL_ARGUMENT ]
  #[ '--file-ea',  GetoptLong::OPTIONAL_ARGUMENT ], # EA file.
  #[ '--dir-bt',   GetoptLong::OPTIONAL_ARGUMENT ], # Dir with backtest files.
  #[ '--dir-sets', GetoptLong::OPTIONAL_ARGUMENT ]  # Dir with set files.
)

provider='virtualbox'
opts.each do |opt, arg|
  case opt
    when '--provider'
      provider=arg
=begin
# @todo: When implementing below, please make sure that running of: 'vagrant -f destroy' would be supported (no invalid option error is shown).
    when '--file-ea'
      file_ea==arg
    when '--dir-bt'
      dir_bt=arg
    when '--dir-sets'
      dir_sets=arg
=end
  end
end

# Vagrantfile API/syntax version.
Vagrant.configure(2) do |config|

  config.vm.hostname = "vagrant"
  config.vm.provision "shell", path: "scripts/provision.sh"
    # :args => '--file-ea' + opt['--file-ea'].to_s + ' --dir-bt' + opt['--dir-bt'].to_s + ' --dir-sets' + opt['--dir-sets'].to_s # @todo
  config.ssh.forward_agent = true # Enables agent forwarding over SSH connections.
  config.ssh.forward_x11 = true # Enables X11 forwarding over SSH connections.
# config.ssh.pty = true # Use pty for provisioning. Could hang the script.
  config.vm.synced_folder ".", "/vagrant", id: "core", nfs: true

  config.vm.define "mt-#{provider}"

  config.vm.provider "virtualbox" do |vm|
    vm.name = "mt-tester.local"
    # vm.network "private_network", ip: "192.168.22.22"
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

  # Plugins
  if Vagrant.has_plugin?("vagrant-timezone")
    config.timezone.value = :host
  end
  if Vagrant.has_plugin?("vagrant-cachier")
    # Configure cached packages to be shared between instances of the same base box.
    # More info on http://fgrehm.viewdocs.io/vagrant-cachier/usage
    config.cache.scope = :box
  end

end
