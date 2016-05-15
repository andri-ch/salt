# setup lvm2 and create the needed logical volumes(LVs)

### Make sure needed cmds exist ###
utilities:                         # ID declaration
  pkg.installed:
    - pkgs:
      - e2fsprogs                  # resize2fs cmd
      - util-linux                 # fdisk, mkfs cmds
      - parted                     # partprobe cmd
      - coreutils                  # chroot cmd


#### Resize first partition ###

# Remember, /dev/xvdb is the harddisk, as used by fdisk, /dev/xvdb1 is the first partition on it


###############################################################
# GLOBAL VARIABLES, SET THEM HERE FOR THE REST OF THE SCRIPT ##
###############################################################
{% set RAM = 512 %}     # 256 | 512 | 1024 | 2048 | 4096 | ... | 30Gb       
# RAM = 256 -> 10Gb hdd
#     = 512 -> 20Gb hdd
#     ...
#     = 30Gb -> 1Tb hdd
# TODO: if RAM is set here, unset it below, when creating LVs(in lvm_setup.sls)
{% set hdd = '/dev/xvdb' %}
{% set partition = '/dev/xvdb1' %}
{% set lvm_partition = '/dev/xvdb2' %}
# set salt-master ip:
{% set ip = '10.178.196.212' %}        # give ip used for Rackspace ServiceNet network
{% set id = '%s' | format(grains['nodename']) | replace('RESCUE-', '', count=1) %}         

{{ partition }}:
  file:
    - exists
    - require:
      - pkg: utilities


# resize filesystem first, then resize partition.
# adjust filesystem size depending if machine is 256 RAM -> 10Gb hdd or 512 RAM -> 20Gb hdd
{% set size = '1500M' if RAM == 256 else '2500M' %}            
# larger than 2500Mb is not practical, even for 30Gb RAM VMs

# check filesystem
check_fs:                                 # unique ID declaration
  cmd.run:                                # .run() fct. of 'cmd' state
    - name: e2fsck -p {{ partition }}     # 'name' keyword arg. to .run() and its value: e2fsck -p {{ partition }}
    - require:
      - file: {{ partition }}             # everything in Linux is a file: dirs, partitions, etc.  

resize_fs:
  cmd.run:
    - name: resize2fs -f {{ partition }} {{ size }}       # force resize, overridding safety checks(done by check_fs anyway)  
    - require:
      - cmd: check_fs

# the following 3 states are neccessary because cmd.script didn't work well
copy_partition_creator:
# size of partition will be slightly larger than size of filesystem
{% set size = '+1520M' if RAM == 256 else '+2520M' %}         # size uses fdisk's syntax
  file.managed:
    - name: /usr/local/lib/create_partitions.py              # path on minion
    - source: salt://lvm/resources/create_partitions.py                # path on master(in the fileserver)
    - template: jinja
    - defaults:                                             # vars available in file
        hdd: {{ hdd }}                                      # notice the lack of dashes before vars
        size: {{ size }}
    - mode: 744                                             # mode is vital if file is to be run with cmd.run
    - require:
      - cmd: resize_fs      

run_partition_creator:
  cmd.run:                               
    # resize original partition and create the second one as Linux LVM
    - name: /usr/local/lib/create_partitions.py             
    - stateful: true                                         # true, not True
    - require:
      - file: copy_partition_creator
    
del_partition_creator:
  file.absent:                                               # remove file or make sure it doesn't exist
    - name: /usr/local/lib/create_partitions.py
    - require: 
      - cmd: run_partition_creator

# read the partition table without restarting
read_part_table:
  cmd.run:
    - name: partprobe -s {{ hdd }}
    # eg.   partprobe -s /dev/xvdb             # read partition table of /dev/xvdb
    # might not list all the partitions, but you can see them with:
    # sudo fdisk -l
    - require:
      - file: del_partition_creator

### DEBUG ###
#list_part_table:
#  cmd.run:
#    - name: fdisk -l
#    - require: 
#      - cmd: read_part_table

mount_dev_xvdb1:            # after creating lvm partition, /dev/xvdb1 will contain / filesystem
  cmd.run:
    - name: mount /dev/xvdb1 /mnt
    - require:
      - cmd: read_part_table


### Install software on disabled server ###
##########################################
install_progs_step_1:
  cmd.run:
    - name: chroot /mnt apt-get --assume-yes install python-software-properties           
                                                    # provides add-apt-repository
    # chroot uses by default /bin/sh to run apt-get ... under /mnt new root
    # python-software-properties (in Ubuntu 11.10, 12.04) is renamed to software-properties-common in ubuntu 12.10
    - onlyif: chroot /mnt apt-get update
    - require:
      - cmd: mount_dev_xvdb1

add_salt_repository:
  # Add salt ppa to sources.list, assume yes to all questions
  cmd.run:
    - name: chroot /mnt add-apt-repository --yes ppa:saltstack/salt
    - require: 
      - cmd: install_progs_step_1

install_salt_minion:
  cmd.run:
    - name: chroot /mnt apt-get --assume-yes install salt-minion
    # prevent "Error: cannot locate package salt-minion" that occurrs after adding salt ppa:
    - onlyif: chroot /mnt apt-get update
    - require: 
      - cmd: add_salt_repository

install_lvm2:
  cmd.run:
    - name: chroot /mnt apt-get --assume-yes install lvm2
    - require:
      - cmd: install_salt_minion


### 3 states left here in case scripts need to be run with chroot ###

#copy_software_installer:
## software_installer installs salt-minion & lvm2
#  file.managed:
#    - name: /mnt/usr/local/lib/software_installer.sh
#    - source: salt://lvm/resources/software_installer.sh
#    - mode: 744                        # this way can be executed by cmd.run
#    - require:
#      - cmd: mount_dev_xvdb1
#
#run_software_installer_with_chroot:
#  cmd.run:
#    # run `bash /usr/local/lib/software_installer.sh` with root set to /mnt
#    - name: chroot /mnt /bin/bash /usr/local/lib/software_installer.sh             #  maybe /bin/sh is better than /bin/bash
#    - stateful: true
#    - require:
#      - file: copy_software_installer
#
#del_software_installer:
#  file.absent:                    
#    - name: /mnt/usr/local/lib/software_installer.sh
#    - require:
#      - cmd: run_software_installer_with_chroot



# Update salt-minion config
update_master:
  file.sed:
    - name: /mnt/etc/salt/minion 
    # before and after should contain the minimal text to be changed.
    # the line to be changed is:   #master: salt
    - before: '#master: salt'
    - after: 'master: {{ ip }}'                    
    # eg. after = 'master: 10.178.196.212'
    - limit: ''                                       # 'limit' - text to the left of the regexp to be matched, starting from ^
    # the limit pattern should be as specific as possible
    - require: 
      #- cmd: run_software_installer_with_chroot
      - cmd: install_salt_minion

# initial id = 'RESCUE-tester'
# after format&replace id = 'tester'
# Remember, grains['nodename'] of the rescue server's grains is used
# eg. grains['nodename'] = RESCUE-tester;     'RESCUE' is added to VM id by Rackspace, by default
# Rescuer grains['nodename'] is not the same nodename as the disabled server:
# grains['nodename'] = tester   # its the VM name assigned from Rackspace control panel.

update_ip:
  file.sed:
    - name: /mnt/etc/salt/minion 
    - before: '#id:'
    - after: "id: {{ id }}"               
    - limit: ''
    - require: 
      - file: update_master


## Setup LVM2 ###
##################################

{{ lvm_partition }}:
  file:
    - exists

### Setup lvm2 from RESCUER ###
lvm2:
  pkg.installed:
    - require: 
      - file: {{ lvm_partition }}
      - file: update_ip          # don't install lvm is minion is not working
    
init_pv:
  # init PV(physical partition)
  cmd.run:
    - name: pvcreate {{ lvm_partition }}
    # eg.   pvcreate /dev/xvdb2
    - require:
      - pkg: lvm2

#### DEBUG ###
# make sure your LVM harddisk is detected by Ubuntu
pvscan:
  cmd.run:
    - require: 
      - cmd: init_pv

# Create VG & add PV to volume group
create_vg:
  cmd.run:
    - name: vgcreate vgpool {{ lvm_partition }}
    - require:
      - cmd: pvscan

# DEBUG ###
# scan for volume groups
vgscan:
  cmd.run:
    - require: 
      - cmd: create_vg

### testing; dummy state needed by other sls files, like lvm_setup.sls
## comment out if not testing 
#vgscan:
#  cmd.run
