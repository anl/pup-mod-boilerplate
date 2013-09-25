pup-mod-boilerplate
===================

Approximate workflow, for the example module "anl/gitwww":

    cd vagrant-puppet # Directory where Puppet modules are grouped for Vagrant
    puppet module generate anl-gitwww
    mv anl-gitwww gitwww # Rename directory to be Vagrant-friendly
    cd gitwww
    git init
    cat > .gitignore <<EOF
    *~
    *#
    .ruby-version
    .vagrant
    Gemfile.lock
    EOF
    rbenv local 1.9.3-p448 # version set by argument/variable
    cat > Gemfile <<EOF
    source 'https://rubygems.org'
    gem 'puppet-lint'
    gem 'puppet', '>= 3.0'
    EOF
    cat > Vagrantfile <<EOF
    VAGRANTFILE_API_VERSION = "2"
    Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
      config.vm.box = "precise64"
      config.vm.box_url = "http://files.vagrantup.com/precise64_vmware.box"
      config.vm.provision :puppet do |puppet|
        puppet.manifests_path = "vagrant"
        puppet.manifest_file = "vagrant.pp"
        puppet.module_path = "../"
      end
    end
    EOF
    mkdir vagrant
    cat > vagrant/vagrant.pp <<EOF
    # Include this module
    include gitwww
    EOF
    git add .
    git commit -m 'Initial commit: Puppet module boilerplate.'
