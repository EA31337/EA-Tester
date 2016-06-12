# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'getoptlong'

# Parse CLI arguments.
opts = GetoptLong.new(
  [ '--keypair-name', GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--private-key',  GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--provider',     GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--subnet-id', GetoptLong::OPTIONAL_ARGUMENT ]
  #[ '--file-ea',  GetoptLong::OPTIONAL_ARGUMENT ], # EA file.
  #[ '--dir-bt',   GetoptLong::OPTIONAL_ARGUMENT ], # Dir with backtest files.
  #[ '--dir-sets', GetoptLong::OPTIONAL_ARGUMENT ]  # Dir with set files.
)

keypair_name=ENV['KEYPAIR_NAME']
private_key=ENV['PRIVATE_KEY']
provider='virtualbox'
subnet_id=ENV['SUBNET_ID']
begin
  opts.each do |opt, arg|
    case opt
      when '--keypair-name'
        keypair_name=arg
      when '--private-key'
        private_key=arg
      when '--provider'
        provider=arg
      when '--subnet-id'
        subnet_id=arg
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

  config.ssh.forward_agent = true # Enables agent forwarding over SSH connections.
  config.ssh.forward_x11 = true # Enables X11 forwarding over SSH connections.
# config.ssh.pty = true # Use pty for provisioning. Could hang the script.
  config.vm.define "mt-#{provider}"
  config.vm.hostname = "vagrant"
  config.vm.provision "shell", path: "scripts/provision.sh"
    # :args => '--file-ea' + opt['--file-ea'].to_s + ' --dir-bt' + opt['--dir-bt'].to_s + ' --dir-sets' + opt['--dir-sets'].to_s # @todo

  config.vm.provider "virtualbox" do |vbox, override|
    vbox.cpus = 2
    vbox.customize ['modifyvm', :id, '--natdnshostresolver1', 'on']
    vbox.name = "mt-tester.local"
    vbox.memory = 4096
    override.cache.auto_detect = true # Enable cachier for local vbox VMS.
    override.vm.network :private_network, ip: "192.168.22.22"
    override.vm.box = "ubuntu/wily64"
    override.vm.synced_folder ".", "/vagrant", id: "core", nfs: true
    if Vagrant.has_plugin?("vagrant-cachier")
      # Configure cached packages to be shared between instances of the same base box.
      # More info on http://fgrehm.viewdocs.io/vagrant-cachier/usage
      override.cache.scope = :box
    end
  end

  config.vm.provider :aws do |aws, override|
    aws.ami = "ami-fce3c696"
    aws.aws_profile = "MT-testing"
    aws.elastic_ip = true
    aws.instance_type = "t2.small"
    aws.keypair_name = keypair_name
    aws.region = "us-east-1"
    aws.tags = { 'Name' => 'MT4'}
    aws.terminate_on_shutdown = true
    if private_key then override.ssh.private_key_path = private_key end
    if subnet_id then aws.subnet_id = subnet_id end
    override.ssh.username = "ubuntu"
    override.vm.box = "mt4-backtest"
    override.vm.box_url = "https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box"
#aws.instance_type = "m3.medium" # 7747d01e
  end

  config.vm.provider :esx do |esx, override|
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
