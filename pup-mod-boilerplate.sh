#!/bin/bash

set -e

ruby_default_vers=1.9.3-p448
RUBY_VERSION=${RUBY_VERSION:-$ruby_default_vers}

puppet module generate ${2}-${1}
mv ${2}-${1} ${1}
cd ${1}

git init
cat > .gitignore <<EOF
*~
*#
.ruby-version
.vagrant
Gemfile.lock
EOF

rbenv local $RUBY_VERSION
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
include $1
EOF

git add .
git commit -m 'Initial commit: Puppet module boilerplate.'
