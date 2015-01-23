#!/bin/bash
# puppet-bootstrapper.bash

# This script will install puppet and configure it for a first time run

puppetmaster=puppetmaster  # Puppet master cert
puppetmasterip=0.0.0.0     # Puppet master IP
environment=testing        # Puppet environment


# We'll only run if we are root
if [ $(whoami) != 'root' ]; then
    echo "This script must be run as root"
    exit 1
fi

# If puppet is isntalled then we bail
if [ -x /usr/bin/puppet ]; then
    echo "Doing nothing because puppet is already installed; bye bye."
    exit 1
fi

# Our operating system determines where we get the package
uname -a | grep Ubuntu > /dev/null && os=deb
uname -a | grep el7    > /dev/null && os=el7
uname -a | grep el6    > /dev/null && os=el6
uname -a | grep el5    > /dev/null && os=el5

# Get the hostname of the machine
hostname=$(hostname)

echo
echo "OS type: $operatingsystem"
echo "Hostname: $hostname"
echo
echo

# Function to quit the script
quit () {
    echo "An error has occured; we're bailing"
    exit 1
}

trap quit SIGINT SIGTERM

# Check that /application_downloads exitst then move to it
if [ -d /application_downloads ]; then
    echo "Directory /application_downloads exists."
else
    echo "Directory /application_downloads does not exists; creating it."
    mkdir /application_downloads
fi

echo
echo "Moving to /applcation_downloads"
echo
cd /application_downloads

# Now we download and install puppet
case $os in
    "deb")
        echo "Downloading puppet repo..."
        echo
        wget -q http://apt.puppetlabs.com/puppetlabs-release-precise.deb || quit
        sleep 1
        echo "Installing repo..."
        echo
        dpkg -i puppetlabs-release-precise.deb || quit
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
    'el5')
        echo "Installing puppet repo..."
        echo
        rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-5.noarch.rpm
        sleep 1
        echo "Installing puppet..."
        echo
        yum install puppet
        sleep 1
        ;;
    'el6')
        echo "Installing puppet repo..."
        echo
        rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm
        sleep 1
        echo "Installing puppet..."
        echo
        yum install puppet
        sleep 1
        ;;
    'el7')
        echo "Installing puppet repo..."
        echo
        rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm
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
echo "    server = $puppetmaster"  >> /etc/puppet/puppet.conf
echo "    environment = $environment" >> /etc/puppet/puppet.conf

echo
echo "Puppet is installed and ready for first run!"
echo "Run 'puppet agent --test' to configure your system"
echo

echo "$puppetmasterip $puppetmaster" >> /etc/hosts
exit 0
