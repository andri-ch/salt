#!/bin/bash

apt-get update
# Add salt ppa to sources.list, assume yes to all questions
apt-get --assume-yes install python-software-properties            # provides add-apt-repository
# python-software-properties (in Ubuntu 11.10, 12.04) is renamed to software-properties-common in ubuntu 12.10      
add-apt-repository --yes ppa:saltstack/salt
add-get update
#sleep 10                     # prevent "Error: cannot locate package salt-minion" that occurrs after adding salt ppa
apt-get --assume-yes install salt-minion
apt-get --assume-yes install lvm2


# writing the state line
echo            # an empty line here so the next line will be the last. Don't use print() for empty lines
echo "changed=yes comment='Installed salt-minion and lvm2'"
