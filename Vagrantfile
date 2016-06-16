# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'getoptlong'

# Parse CLI arguments.
opts = GetoptLong.new(
  [ '--asset',          GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--cpus',           GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--keypair-name',   GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--memory',         GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--private-key',    GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--provider',       GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--security-group', GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--subnet-id',      GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--vm-name',        GetoptLong::OPTIONAL_ARGUMENT ],
  #[ '--file-ea',  GetoptLong::OPTIONAL_ARGUMENT ], # EA file.
  #[ '--dir-bt',   GetoptLong::OPTIONAL_ARGUMENT ], # Dir with backtest files.
  #[ '--dir-sets', GetoptLong::OPTIONAL_ARGUMENT ]  # Dir with set files.
)

asset=ENV['ASSET']
cpus=ENV['CPUS'] || 2
gh_token=ENV['GITHUB_API_TOKEN']
keypair_name=ENV['KEYPAIR_NAME']
memory=ENV['MEMORY'] || 2048
private_key=ENV['PRIVATE_KEY']
provider=ENV['PROVIDER'] || 'virtualbox'
security_group=ENV['SECURITY_GROUP']
subnet_id=ENV['SUBNET_ID']
vm_name=ENV['VM_NAME'] || 'default'
begin
  opts.each do |opt, arg|
    case opt
      when '--asset';          asset          = arg
      when '--cpus';           cpus           = arg.to_i
      when '--keypair-name';   keypair_name   = arg
      when '--memory';         memory         = arg.to_i
      when '--private-key';    private_key    = arg
      when '--provider';       provider       = arg
      when '--security-group'; security_group = arg
      when '--subnet-id';      subnet_id      = arg
      when '--vm-name';        vm_name        = arg
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
  config.vm.define "mt-#{provider}-#{vm_name}"
  config.vm.hostname = "vagrant"
  config.vm.provision "shell", path: "scripts/provision.sh"
    # :args => '--file-ea' + opt['--file-ea'].to_s + ' --dir-bt' + opt['--dir-bt'].to_s + ' --dir-sets' + opt['--dir-sets'].to_s # @todo
# config.vm.synced_folder ".", "/vagrant", id: "core", nfs: true

  if asset
    config.vm.provision "shell" do |s|
      s.binary = true # Replace Windows line endings with Unix line endings.
      s.privileged = false # Run as a non privileged user.
      s.inline = %Q[/usr/bin/env GITHUB_API_TOKEN=#{gh_token} /vagrant/scripts/get_gh_asset.sh #{asset}]
    end
  end

  config.vm.provider "virtualbox" do |vbox, override|
    vbox.customize [ "modifyvm", :id, "--natdnshostresolver1", "on"]
    vbox.customize [ "modifyvm", :id, "--memory", memory ]
    vbox.customize [ "modifyvm", :id, "--cpus", cpus ]
    vbox.name = "mt-tester.local"
    override.cache.auto_detect = true # Enable cachier for local vbox VMS.
    override.vm.box = "ubuntu/wily64"
    override.vm.network :private_network, ip: "192.168.22.22"
    override.vm.synced_folder ".", "/vagrant", id: "core", nfs: true
    # Configure VirtualBox environment
    if Vagrant.has_plugin?("vagrant-cachier")
      # Configure cached packages to be shared between instances of the same base box.
      # More info on http://fgrehm.viewdocs.io/vagrant-cachier/usage
      override.cache.scope = :box
    end
  end

  # AWS EC2 provider
  config.vm.provider :aws do |aws, override|
    aws.ami = "ami-fce3c696"
    aws.aws_profile = "MT-testing"
    aws.elastic_ip = true
    aws.instance_type = "t2.small"
    aws.keypair_name = keypair_name
    aws.region = "us-east-1"
    aws.tags = { 'Name' => 'MT4-' + vm_name }
    aws.terminate_on_shutdown = true
    if private_key then override.ssh.private_key_path = private_key end
    if security_group then aws.security_groups = [ security_group ] end
    if subnet_id then aws.subnet_id = subnet_id end
    override.nfs.functional = false
    override.ssh.username = "ubuntu"
    override.vm.box = "mt4-backtest"
    override.vm.box_url = "https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box"
  # aws.instance_type = "m3.medium" # 7747d01e
  end

  config.vm.provider :managed do |managed, override|
    override.vm.box = "managed_dummy_box"
    override.vm.box_url = "https://github.com/tknerr/vagrant-managed-servers/raw/master/dummy.box"
  # managed.server = server # link with this server
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

  if Vagrant.has_plugin?("vagrant-vbguest")
    # Set auto_update to false, if you do NOT want to check the correct 
    # additions version when booting this machine.
    config.vbguest.auto_update = true

    # Do NOT download the iso file from a webserver.
    config.vbguest.no_remote = false

    config.vbguest.installer_arguments = ['--nox11']
  end

end
