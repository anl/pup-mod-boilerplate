#!/bin/bash

set -e

# Default values:
ruby_default_vers=2.1.2

function usage {
    echo "Usage: $0 -n module_name -a module_author [ -r ruby_version ] [ -v ]"
    echo "       $0 -h"
    echo
    echo "  -a  Puppet forge module author name"
    echo "  -h  Print this usage message"
    echo "  -n  Puppet module name"
    echo "  -r  Ruby version (default: ${ruby_default_vers})"
    echo "  -v  Be verbose"
    exit 1
}

while getopts "a:hn:r:v" flag ; do
    case $flag in
	a) author=$OPTARG ;;
	h) usage ;;
	n) mod_name=$OPTARG ;;
	r) ruby_vers=$OPTARG ;;
	v) verbose=true ;;
	*) usage ;;
    esac
done

verbose_on=${verbose:-false}
if [[ $verbose_on == 'true' ]] ; then
    set -x
fi

if [ -z "$author" ] ; then
    echo "Module author must be set."
    echo
    usage
fi

if [ -z "$mod_name" ] ; then
    echo "Module name must be set."
    echo
    usage
fi

# Determine which puppet binary to use:

set +e
bundle exec puppet > /dev/null 2>&1
bxpuppet_out=$?
puppet > /dev/null 2>&1
syspuppet_out=$?
set -e

if [ $bxpuppet_out -eq 0 ] ; then
    puppet='bundle exec puppet'
elif [ $syspuppet_out -eq 0 ] ; then
    puppet='puppet'
else
    echo '"puppet" executable not found.'
    echo
    usage
fi

ruby_vers=${ruby_vers:-$ruby_default_vers}
eval "$(rbenv init -)"
rbenv shell $ruby_vers

$puppet module generate ${author}-${mod_name}
mv ${author}-${mod_name} ${mod_name}
cd ${mod_name}

git init
cat > .gitignore <<EOF
*~
*#
.ruby-version
.vagrant
Gemfile.lock
EOF

cd .git/hooks
wget https://raw.github.com/anl/puppet-git-hooks/master/hooks/pre-commit
chmod 755 pre-commit
cd ../..

rbenv local $ruby_vers
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
  unless ENV['NO_VAGRANT_APTGET']
    config.vm.provision :shell, :inline => '/usr/bin/apt-get update'
  end
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
include $mod_name
EOF

git add .
git commit -m 'Initial commit: Puppet module boilerplate.'
