# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'getoptlong'

# Parse CLI arguments.
opts = GetoptLong.new(
  [ '--asset',          GetoptLong::OPTIONAL_ARGUMENT ], # Asset to download (see: get_gh_asset.sh).
  [ '--clone-repo',     GetoptLong::OPTIONAL_ARGUMENT ], # Clone git repository.
  [ '--cpus',           GetoptLong::OPTIONAL_ARGUMENT ], # Number of CPUs.
  [ '--ec2-region',     GetoptLong::OPTIONAL_ARGUMENT ], # EC2 region.
  [ '--git-args',       GetoptLong::OPTIONAL_ARGUMENT ], # Git arguments for commit (e.g. author).
  [ '--github-token',   GetoptLong::OPTIONAL_ARGUMENT ], # GitHub API access token.
  [ '--instance-type',  GetoptLong::OPTIONAL_ARGUMENT ], # EC2 instance type.
  [ '--keypair-name',   GetoptLong::OPTIONAL_ARGUMENT ], # SSH access keypair name (EC2).
  [ '--memory',         GetoptLong::OPTIONAL_ARGUMENT ], # Size of memory.
  [ '--no-setup',       GetoptLong::OPTIONAL_ARGUMENT ], # No setup when set.
  [ '--power-off',      GetoptLong::OPTIONAL_ARGUMENT ], # Power off when set.
  [ '--private-key',    GetoptLong::OPTIONAL_ARGUMENT ], # Path to private key.
  [ '--provider',       GetoptLong::OPTIONAL_ARGUMENT ], # Name of provider (e.g. aws).
  [ '--push-repo',      GetoptLong::OPTIONAL_ARGUMENT ], # Push changes when set.
  [ '--run-test',       GetoptLong::OPTIONAL_ARGUMENT ], # Arguments for run_backtest.sh.
  [ '--security-group', GetoptLong::OPTIONAL_ARGUMENT ], # Name of EC2 security group.
  [ '--subnet-id',      GetoptLong::OPTIONAL_ARGUMENT ], # Name of subnet ID (EC2).
  [ '--terminate',      GetoptLong::OPTIONAL_ARGUMENT ], # Terminate instance when set.
  [ '--vm-name',        GetoptLong::OPTIONAL_ARGUMENT ], # Name of the VM.
)

asset          = ENV['ASSET']
clone_repo     = ENV['CLONE_REPO']
cpus           = ENV['CPUS'] || 2
ec2_region     = ENV['EC2_REGION'] || 'us-east-1'
git_args       = ENV['GIT_ARGS']
github_token   = ENV['GITHUB_API_TOKEN']
instance_type  = ENV['INSTANCE_TYPE'] || 't2.small'
keypair_name   = ENV['KEYPAIR_NAME']
memory         = ENV['MEMORY'] || 2048
no_setup       = ENV['NO_SETUP']
power_off      = ENV['POWER_OFF']
private_key    = ENV['PRIVATE_KEY']
provider       = ENV['PROVIDER'] || 'virtualbox'
push_repo      = ENV['PUSH_REPO']
run_test       = ENV['RUN_TEST']
security_group = ENV['SECURITY_GROUP']
subnet_id      = ENV['SUBNET_ID']
terminate      = ENV['TERMINATE']
vm_name        = ENV['VM_NAME'] || 'default'
begin
  opts.each do |opt, arg|
    case opt
      when '--asset';          asset          = arg.to_s
      when '--clone-repo';     clone_repo     = arg.to_s
      when '--cpus';           cpus           = arg.to_i
      when '--ec2-region';     ec2_region     = arg.to_s
      when '--git-args';       git_args       = arg.to_s
      when '--github-token';   github_token   = arg.to_s
      when '--instance-type';  instance_type  = arg.to_s
      when '--keypair-name';   keypair_name   = arg
      when '--memory';         memory         = arg.to_i
      when '--no-setup';       no_setup       = !arg.to_i.zero?
      when '--power-off';      power_off      = arg.to_i
      when '--private-key';    private_key    = arg
      when '--provider';       provider       = arg
      when '--push-repo';      push_repo      = !arg.to_i.zero?
      when '--run-test';       run_test       = arg
      when '--security-group'; security_group = arg
      when '--subnet-id';      subnet_id      = arg
      when '--terminate';      terminate      = !arg.to_i.zero?
      when '--vm-name';        vm_name        = arg
    end # case
  end # each
  rescue
# @todo: Correct an invalid option error.
end
script = ENV['SCRIPT'] || "set -x;"

# Vagrantfile API/syntax version.
Vagrant.configure(2) do |config|

  config.ssh.forward_agent = true # Enables agent forwarding over SSH connections.
  config.ssh.forward_x11 = true # Enables X11 forwarding over SSH connections.
# config.ssh.pty = true # Use pty for provisioning. Could hang the script.
  config.vm.define "mt-#{provider}-#{vm_name}"
  config.vm.hostname = "vagrant"
# config.vm.synced_folder ".", "/vagrant", id: "core", nfs: true


  if not no_setup
    config.vm.provision "shell", path: "scripts/provision.sh"
  end

  if asset
    script << %Q[/usr/bin/env \
                 CLEAN=1 \
                 OVERRIDE=1 \
                 GITHUB_API_TOKEN=#{github_token} \
                 /vagrant/scripts/get_gh_asset.sh #{asset} &&]
  end

  if clone_repo
    script << %Q[/vagrant/scripts/clone_repo.sh "#{clone_repo}" &&]
  end

  if run_test
    script << %Q[/vagrant/scripts/run_backtest.sh #{run_test} &&]
  end

  if push_repo
    # The clone_repo parameter is required for push to work correctly.
    script << %Q[/usr/bin/env \
                 GIT_ARGS='#{git_args}' \
                 /vagrant/scripts/push_repo.sh '#{clone_repo}' '#{vm_name}' 'Test results for #{vm_name}' &&]
  end

  if power_off
    script << "echo Stopping the VM...; sudo poweroff --verbose &&"
  end

  config.vm.provision "shell" do |s|
    s.binary = true # Replace Windows line endings with Unix line endings.
    s.privileged = false # Run as a non privileged user.
    s.inline = script << "echo done"
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
    aws.block_device_mapping = [{ 'DeviceName' => '/dev/sda1', 'Ebs.VolumeSize' => 16 }]
    aws.instance_type = instance_type
    aws.keypair_name = keypair_name
    aws.region = ec2_region
    aws.tags = { 'Name' => 'MT4-' + vm_name }
    aws.terminate_on_shutdown = terminate
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
