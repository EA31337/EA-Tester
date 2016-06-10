# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'getoptlong'

# Parse CLI arguments.
opts = GetoptLong.new(
  [ '--provider',     GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--keypair-name', GetoptLong::OPTIONAL_ARGUMENT ]
  #[ '--file-ea',  GetoptLong::OPTIONAL_ARGUMENT ], # EA file.
  #[ '--dir-bt',   GetoptLong::OPTIONAL_ARGUMENT ], # Dir with backtest files.
  #[ '--dir-sets', GetoptLong::OPTIONAL_ARGUMENT ]  # Dir with set files.
)

provider='virtualbox'
keypair_name=ENV['KEYPAIR_NAME']
begin
  opts.each do |opt, arg|
    case opt
      when '--provider'
        provider=arg
      when '--keypair-name'
        keypair_name=arg
=begin
# @todo: When implementing below, please make sure that running of: 'vagrant -f destroy' would be supported (no invalid option error is shown).
      when '--file-ea'
        file_ea==arg
      when '--dir-bt'
        dir_bt=arg
      when '--dir-sets'
        dir_sets=arg
=end
    end # case
  end # each
  rescue
end

# Vagrantfile API/syntax version.
Vagrant.configure(2) do |config|

  config.vm.hostname = "vagrant"
  config.vm.provision "shell", path: "scripts/provision.sh"
    # :args => '--file-ea' + opt['--file-ea'].to_s + ' --dir-bt' + opt['--dir-bt'].to_s + ' --dir-sets' + opt['--dir-sets'].to_s # @todo
  config.ssh.forward_agent = true # Enables agent forwarding over SSH connections.
  config.ssh.forward_x11 = true # Enables X11 forwarding over SSH connections.
# config.ssh.pty = true # Use pty for provisioning. Could hang the script.

  config.vm.define "mt-#{provider}"

  config.vm.provider "virtualbox" do |vbox, override|
    vbox.cpus = 2
    vbox.customize ['modifyvm', :id, '--natdnshostresolver1', 'on']
    vbox.name = "mt-tester.local"
    vbox.memory = 4096
    override.vm.network "private_network", ip: "192.168.22.22"
    override.vm.box = "ubuntu/wily64"
    override.vm.synced_folder ".", "/vagrant", id: "core", nfs: true
    if Vagrant.has_plugin?("vagrant-cachier")
      # Configure cached packages to be shared between instances of the same base box.
      # More info on http://fgrehm.viewdocs.io/vagrant-cachier/usage
      override.cache.scope = :box
    end
  end

  config.vm.provider :aws do |aws, override|
    aws.ami = "ami-7747d01e"
    aws.aws_profile = "MT-testing"
    aws.instance_type = "m3.medium"
    aws.keypair_name = keypair_name
    aws.tags = {
      'Name' => 'MT4',
    }
    aws.terminate_on_shutdown = true
    override.vm.box = "mt4-backtest"
    override.vm.box_url = "https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box"
    override.ssh.username = "ubuntu"
    if ENV['PRIVATE_KEY_PATH']
      override.ssh.private_key_path = ENV['PRIVATE_KEY_PATH']
    end
    # aws.security_groups = [ "default", "MT" ] # For VPC instances only.
  end

  # Parameters for specific providers.
  case provider
    when "virtualbox"
    when "aws"
  end

  # Extra plugin settings.
  if Vagrant.has_plugin?("vagrant-timezone")
    config.timezone.value = :host
  end

end
