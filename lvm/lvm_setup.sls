#!py

# shebang tells salt to use py renderer, not the default yaml_jinja
# py is used for complex variable operations that make use of python features
# py renderer interprets normal python syntax

import itertools
from collections import OrderedDict

# because grains module is not available by default, like it is for pydsl, 
# jinja, etc. renderers, we make a dirty grains import:
import salt
grains = salt.loader.grains({'grain': '', 'id':'', 'extension_modules':''})
# loader.grains() is a fct. that needs a dict with those keys as argument
# 'id':'' -> on minion on which this script is executed

### Create logical volumes(LVs) and their filesystems ###
#
# define partition names and sizes
# {'home': '600'} => 600Mb, {'tmp':'1'} => 1Gb, etc.
# For consistency, preserve the LV creation/state order execution by creating a base partition:
partitions = OrderedDict([
                    ('home', 600), ('tmp', 1), ('usr', 1), ('usr_local', 1), ('var', 1), 
                    ('var_local', 1), ('var_www', 1), ('var_log', 700), 
                    ('var_spool', 780)
                    ])
# OrderedDict.items() or .iteritems() will always return the elems in the order they were defined

## use this for testing, then comment out: ##
#partitions = OrderedDict([ ('tmp', 1), ('var_spool', 780) ])

### take into account if Virtual Machine is 256mb => 10Gb HDD or 512mb RAM => 20Gb HDD
VM_SIZES = [256, 512, 1024, 2048, 4096, 8192, 15360, 30720]
# Rescue server's RAM is equal to RAM on disabled server, so it is normal to 
# get the RAM from rescue server:
ram_actual = grains['mem_total']               
# Eg. 239 for 256 RAM VM, 489 for a 512 RAM VM, etc.

# Get larger or equal ram sizes:
ram_set = itertools.ifilter(lambda s: ram_actual <= s, VM_SIZES)      
# ifilter(pred, seq) -> elems of VM_SIZES for which lambda returns True
# Smallest value from larger or equal set is the ram size(ram is smaller than 
# VM ram in Cloud Control Panel, it can be equal to it at most)
ram_set = list(ram_set)
RAM = ram_set[0]

coeff = RAM // 256         # // - divide the numbers and return the truncated integer result
# if RAM == 512 => coeff = 2, so sizes for 256Mb RAM need to multiplied by
# coeff, because hdd increases coeff times.

if RAM >= 512:
    # use as much space as you can, with values unchanged space is wasted
    # for a 512 RAM VM, hdd is 21.5 Gb(fdisk output) but `df -h` shows only 19.68 Gb, but df shows the filesystems sizes 
    partitions['var_log'] = 1100
    partitions['var_spool'] = 1080

## multiply sizes with coeff:  
for name, size in partitions.iteritems():        # .iteritems() returns a generator, .items() a list
    partitions[name] = size * coeff
# eg. partitions['home'] = 600 * 2 = 1200
    partitions[name] = str(partitions[name])

    # format sizes according to fdisk's notation: M for Megabytes, G for Gigabytes
    # assume no partitions larger than 99 Gb(2 digit number) exist
    if len(partitions[name]) < 3:                
        partitions[name] = partitions[name] + "G"
# eg.               '20' => '20G'
    else:
       partitions[name] = partitions[name] + "M" 
# eg.             '700' => '700M'



### Create a sls file data structure ###
'''
highstate var. below must be a friendly state.highstate data structure that 
follows these standards:
    http://docs.saltstack.com/ref/states/highstate.html 
'''   
highstate = {'include': ['lvm/init'] }                       # include: list of files to include
                        # lvm/init was included just to make available state 'vgscan'            
 
### Jinja way ### unfortunately didn't work
#
#create_lvs:
#{% for name, size in partitions %}
#  cmd.run:
#    - name: lvcreate -L {{ size }} -n {{ name }} vgpool     
#    # eg: lvcreate -L 1G -n tmp vgpool
#    - require: 
#      - cmd: create_vg         # or activate_vg ??
#  cmd.run:
#    # make filesystem on lv:
#    - name: mkfs -t ext4 /dev/vgpool/{{ name }}
#    # eg: mkfs -t ext4 /dev/vgpool/tmp
#{% endfor %}

# py renderer way:
# the rest of the LVs
it = partitions.items()     
# >>> type(it) 
# list (of 2-tuples)

i = 0
for name, size in it:
    mkfs_on_previous_lv = 'mkfs_on_{0}'.format(it[i-1][0]) if name != 'home' else 'vgscan'
    # name = 'home' will be the first value because 'home is the first elem of the OrderedDict
    # so no index errors will occur, i>=1 by the time it[i-1][0] is called
    highstate['create_lv_%s' % name] = {                     # ID declaration, value is a dictionary
                'cmd': ['run',                               # state, function declaration, one fct/state
                        {'name': 'lvcreate -L {0} -n {1} vgpool'.format(size, name) },
                        # eg:     lvcreate -L 1G -n tmp vgpool
                        {'require': [{'cmd': mkfs_on_previous_lv }] }   
                                   # requires mkfs_on_name-of-previous_lv state
                       ]
                }
    # Make a filesystem on previously created LV:
    highstate['mkfs_on_%s' % name] = {                       # ID declaration, value is a dictionary
                'cmd': ['run',                               # state: list_of_one_fct&its_args;  each arg is a single key dict
                        # make filesystem on lv:
                        {'name': 'mkfs -t ext4 /dev/vgpool/%s' % name },
                        # eg:     mkfs -t ext4 /dev/vgpool/tmp
                        {'require': [{'cmd': 'create_lv_%s' % name}] }      
                        # require ensures a specific state execution order is followed
                       ]
                }
    i += 1

# After creating LVs, activate VG so that LVs become available
# jinja+yaml way:
#activate_vg:
#  cmd.run:
#    - name: vgchange -a y
#    - require: 
       # choose the last key in partitions dict, assume it will be the last LV created
#      - cmd: mkfs_on_var_spool         

# py renderer way:
highstate['activate_vg'] = {
                  'cmd': ['run', {'name': 'vgchange -a y'},
                                 # choose the last key in partitions dict, assume it will be the last LV created
                                 {'require': [{'cmd': 'mkfs_on_var_spool'}] }
                         ]
                  }

#### DEBUG ###
# Jinja way:
## Scan for logical volumes:
#lvscan:
#  cmd.run:
#    - require:
#      - cmd: create_lvs

# py renderer way:
highstate['lvscan'] = {                                      # ID declaration, value is a dictionary
                 'cmd': ['run', {                            # State decl, value is a list with a state fct. as first element, followed by
                                                             # single key dictionaries containing function argument declaration          
                           'require': [
                               {'cmd': 'activate_vg'}]       # change to smth. else
                           }
                        ]
                 } 

highstate['/mnt/etc/fstab'] = {
                    'file': ['managed', {'source': 'salt://lvm/resources/fstab'},
                                        {'user': 'root'},
                                        {'group': 'root'},
                                        {'mode': 644},
                                        {'require': [{'cmd': 'lvscan'}] }
                            ]
                    }

# create /var/www on disabled server, it doesn't exist on a fresh system
highstate['create_var_www'] = {
                    'file': ['directory', {'name': '/mnt/var/www'},
                                   {'user': 'root'},
                                   {'group': 'root'},
                                   {'dir_mode': 755},
                                   {'file_mode': 644},
                                   {'require': [{'file': '/mnt/etc/fstab'}] }
                           ],
                    } 


#### Copy contents from dirs over to their corresponding partition ###
## /usr/local/* to /dev/vgpool/usr_local
## /usr/* to /dev/vgpool/usr/*
## Remember, /dev/vgpool/* are block files, they need to be mounted first
#copy_contents_to_partition:
#{% for key in partitions %}
#{%     set key = key|replace("_", "/") %}
## eg. replace _ with / for every key: if key == 'var_local' => key = 'var/local'
#  cmd.run:
#    - name: mount /dev/vgpool/{{ key }} /mnt
#    - require:
#      - cmd: create_lvs
#  cmd.run:
#    - name: cp -a --copy-contents /{{ key }}/* /mnt/
#    - require:
#      - cmd: create_lvs
#  cmd.run:
#    - name: rm -r /{{ key }}/*
#    - require:
#      - cmd: create_lvs
#  cmd.run:
#    - name: umount /mnt
#    - require:
#      - cmd: create_lvs
#{% endfor %}


### Exclude empty dirs from copy operations ###
# /var/local, /var/www, /tmp, /home are empty on a fresh system, so we exclude them from
# copy operations that take contents from initial partition to corresponding LVs.
# If we don't exclude them, eg. highstate['cp_to_var/www'] below will throw:
# stderr: cp: cannot stat `/mnt/var/www/*': No such file or directory
# If not a fresh system, add excluded dirs back, or data will be lost(data not copied, other fs will be mounted in those dirs)
partitions = OrderedDict([
                    ('usr_local', 1), ('usr', 1), 
                    ('var_log', 700), ('var_spool', 780), ('var', 1), 
                    ])

it = partitions.keys()
# partitions.keys() returns the same list every time because partitions 
# is an OrderedDict => first time key == 'home'

### testing, step 1, comment otherwise ###
# it = ['home', 'var_www']

i = 0
for lv_key in it:
    key = lv_key.replace('_', '/')
    # eg.        replace _ with / for every key: if key == 'var_local' => key = 'var/local'
    if key != 'usr/local':
        dependency = {'cmd': 'del_old_%s' % it[i-1]} 
               # eg. {'cmd': 'del_old_var_log'}
        # testing, step 2, comment otherwise:
        #it_2 = ['usr/local', 'var/www']
        #dependency = {'cmd': 'cp_to_%s' % it_2[i-1]} 
    else:
        dependency = {'file': 'create_var_www'}

    highstate['cp_to_%s' % key] = {               # cp_to_var/log
                    'cmd': ['run', {'name': 'cp -a --copy-contents /mnt/{0}/* /media/{1}/'.format(key, lv_key)},
                                           # cp -a --copy-contents /mnt/var/local/* /media/var_local/
                                   {'onlyif': 'mkdir /media/{0} && mount /dev/vgpool/{0} /media/{0}'.format(lv_key)},
                                             # mkdir /media/var_local && mount /dev/vgpool/var_local /media/var_local
                                   {'require': [dependency] }
                           ]
                    }
    # testing, step 3, uncomment otherwise:
    highstate['del_old_%s' % lv_key] = {          # del_old_var_log
                       'cmd': ['run', {'name': 'rm -r /mnt/{0}/*'.format(key)},
                                      {'require': [{'cmd': 'cp_to_%s' % key}] }
                              ]
                       } 
    i += 1


def run():
    '''
    This fct is mandatory when using "py" renderer. Must return a friendly
    state.highstate data structure that follows these standards:
    http://docs.saltstack.com/ref/states/highstate.html 
    '''
    return highstate 

