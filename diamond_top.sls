#{#         - jinja comment -
#This file provides mappings for other files and can be used to set a base configuration for all servers.
#top.sls is separated into environments: base(default);
# you can define other ones eg. dev, prod, etc.
##}

{% set target = 'Primul-production' %}

### Diamond setup ###
base:
# specify what minions to target
   'localminion':
     - diamond          # by default diamond/init.sls
   {{ target }}: 
     - diamond.remote_diamond_setup
