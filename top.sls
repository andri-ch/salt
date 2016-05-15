#{#         - jinja comment -
#This file provides mappings for other files and can be used to set a base configuration for all servers.
#top.sls is separated into environments: base(default);
# you can define other ones eg. dev, prod, etc.
##}
base:
#  'tester':              # specify what minions to target
#    - ssh           # include ssh sls module(it can be either a file: ssh.sls or a dir: ssh/init.sls) 
#    - lvm
#    - lvm.lvm_setup
#  'rescuer':
#    - lvm
#    - lvm.lvm_setup

### Diamond setup ###
   'localminion':
     - diamond          # by default diamond/init.sls
   'Primul-production':
     - diamond.remote_diamond_setup
