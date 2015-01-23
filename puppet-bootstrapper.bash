#!/bin/bash
# puppet-bootstrapper.bash

# This script will install puppet and configure it for a first time run

# Defaults for our variables
mycert=my.example.cert           # Cert for this client
puppetmaster=master.example.cert # Puppet master cert
puppetmasterip=0.0.0.0           # Puppet master IP
environment=testing              # Puppet environment

# Set from configuration file
[ -r "$1" ] && . "$1"

# Set from the environment
[ "$MYCERT" != '' ] && mycert=$MYCERT
[ "$PMCERT" != '' ] && puppetmaster=$PMCERT
[ "$PMADDR" != '' ] && puppetmasterip=$PMADDR
[ "$ENVIRO" != '' ] && environment=$ENVIRO

# Check usage
[ "$1" == '--help' ] && echo -e "Usage: $0 [CONF]\nInstall puppet and configure it for a first time run." && exit 0

# We'll only run if we are root
if [ $(whoami) != 'root' ]; then
    echo "This script must be run as root."
    exit 1
fi

# Function to quit the script
quit () {
    echo "An error has occured; we're bailing."
    exit 1
}

trap quit SIGINT SIGTERM

# If puppet is installed then we bail
if [ -x /usr/bin/puppet ]; then
    echo "Doing nothing because puppet is already installed; bye bye."
    exit 1
fi

# Determine the package to install
uname -a | grep precise > /dev/null && os=deb && pkg=puppetlabs-release-precise.deb
uname -a | grep el7     > /dev/null && os=el  && pkg=puppetlabs-release-el-7.noarch.rpm
uname -a | grep el6     > /dev/null && os=el  && pkg=puppetlabs-release-el-6.noarch.rpm
uname -a | grep el5     > /dev/null && os=el  && pkg=puppetlabs-release-el-5.noarch.rpm

# Now we download and install puppet
case $os in
    'deb')
        echo "Downloading puppet repo..."
        echo
        wget -q http://apt.puppetlabs.com/$pkg || quit
        sleep 1
        echo "Installing repo..."
        echo
        dpkg -i $pkg || quit
        sleep 1
        echo "Updating apt-get..."
        echo
        apt-get -qq update || quit
        sleep 1
        echo "Installing puppet..."
        echo
        apt-get -qq -y -o DPkg::Options::=--force-confold install puppet || quit
        sleep 1
        ;;
    'el')
        echo "Installing puppet repo..."
        echo
        rpm -ivh http://yum.puppetlabs.com/$pkg
        sleep 1
        echo "Installing puppet..."
        echo
        yum install puppet
        sleep 1
        ;;
    *) 
        echo "Sorry, your OS is not supported yet. Bye Bye."
        exit 1
        ;;
esac

# Clean up the /etc/puppet directory
echo
echo "Cleaning /etc/puppet"
echo
rm -rf /etc/puppet/* || quit
[ -d /etc/puppet ] || mkdir /etc/puppet

echo "Creating first-run configuration file"
> /etc/puppet/puppet.conf || quit
echo "[main]"                         >> /etc/puppet/puppet.conf
echo "    report = true"              >> /etc/puppet/puppet.conf
echo "    reports = log,store"        >> /etc/puppet/puppet.conf
echo "[agent]"                        >> /etc/puppet/puppet.conf
echo "    report = true"              >> /etc/puppet/puppet.conf
echo "    certname = $mycert"         >> /etc/puppet/puppet.conf
echo "    server = $puppetmaster"     >> /etc/puppet/puppet.conf
echo "    environment = $environment" >> /etc/puppet/puppet.conf

echo
echo "Puppet is installed and ready for first run!"
echo "Run 'puppet agent --test' to configure your system"
echo

# Add the puppet master to /etc/hosts
grep $puppetmaster /etc/hosts > /dev/null || echo "$puppetmasterip $puppetmaster" >> /etc/hosts

exit 0
