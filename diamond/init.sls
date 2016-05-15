#!py

#### FAILED PYDSL renderer attempt ###
##!pydsl
#
## uses pydsl renderer: http://docs.saltstack.com/ref/renderers/all/salt.renderers.pydsl.html
#
## implicit ordering of states; only if minions are using Python >= 2.7
#__pydsl__.set(ordered=True)
#
## state('mk_diamond')          # ID declaration
#state('mk_diamond').file.directory('/usr/local/src/diamond', dir_mode=755)   
## .file is the state declaration obj
## .directory is the function declaration obj
#
#state('mk_diamond').cmd.run('git clone git://github.com/BrightcoveOS/Diamond.git diamond') 
#
##########################################


# This script was created to be run only by the minion on master server
# For details regarding sls logic, read Tomboy's Diamond-> Salt Stack diamond setup

import os.path
import glob
import hashlib              # used for hashing files

### Create a sls file data structure ###
'''
highstate var. below must be a friendly state.highstate data structure that 
follows these standards:
    http://docs.saltstack.com/ref/states/highstate.html 
'''   
# highstate['ID_declaration'] = {                                    # ID declaration, value is a dictionary
#                 'state_decl' : ['func_name',    
#                                     {'arg1': 'value1'},            # each arg is a one key dictionary
#                                     {'arg2': 'value2'},
#                                ],                                                 
#                  }

### INIT ###
highstate = {}
diamond_path = '/usr/local/src/diamond'


# make sure diamond_path is empty, that's required by git clone => del & recreate
highstate['del_diamond_dir'] = {
                'file': ['absent',                                          # verify that a file or directory is absent
                            {'name': '%s' % diamond_path},
                        ],
                }

highstate['mk_diamond_dir'] = {
                'file': ['directory',                                       # ensure that a directory is present
                            {'name': '%s' % diamond_path},
                            {'dir_mode': 755},
                            {'require': [{'file': 'del_diamond_dir'},       # state function requisite
                                        ]}
                        ],
                }

highstate['git'] = {
            'pkg': ['installed'],
            'require': [{'file': 'mk_diamond_dir'}]      # state requisite          
            }

highstate['get_latest_src'] = {
                'cmd': ['run',
                           {'name': 'git clone git://github.com/BrightcoveOS/Diamond.git /usr/local/src/diamond'},
                           {'require': [{'file': 'mk_diamond_dir'}, 
                                        {'pkg': 'git'},
                                       ]}
                       ],
                }                    

highstate['build_utilities'] = {
                'pkg': ['installed',
                            {'pkgs': ['build-essential', 'make', 'dpkg-dev', 'pbuilder', 'python-mock', 
                                      'python-configobj', 'python-support', 'cdbs']},
                            {'require': [{'cmd': 'get_latest_src'},
                                        ]}
                       ],
                }

highstate['builddeb'] = {
                'cmd': ['run',
                            {'name' : 'make builddeb'},
                            {'cwd': '%s' % diamond_path}, 
                            {'require': [{'pkg': 'build_utilities'},
                                        ]}
                       ],
                }

# figure out the path to diamond_*.deb file, because after each build, name changes
deb_path = os.path.join(diamond_path, 'build', '*.deb')

'''
# Eg.
>>> deb_path
'/usr/local/src/diamond/build/*.deb'
>>> deb_path = glob.glob(deb_path)[0]              # a list of paths, we expect to have one element (one *.deb file)
>>> deb_path
'/usr/local/src/diamond/build/diamond_3.3.485_all.deb'
'''


highstate['copy_deb_to_file_server'] = {
                'cmd': ['run',
                            {'name': 'cp %s /srv/salt/diamond/resources/diamond.deb' % glob.glob(deb_path)[0] },   # compute glob here to ensure it is computed after diamond.deb has been built in the previous state
                            {'require': [{'cmd': 'builddeb'},
                                        ]}
                        ],
                }
                             

# Now that the diamond.deb file is built and copied to salt file server(/srv/salt) so 
# that other minions can access it, fire an event off on the 
# salt-master will react based on his rector config by running a reactor sls file 
# that will trigger state.highstate on minion where diamond will be installed.
highstate['fire_deb_built_event'] = {
                'cmd': ['run',
                            {'name': 'salt "localminion" event.fire_master id="localminion" "diamond.deb built"'},
                            {'require': [{'cmd': 'copy_deb_to_file_server'},
                                        ]}
                       ],
                }
 

def run():
    '''
    This fct is mandatory when using "py" renderer. Must return a friendly
    state.highstate data structure that follows these standards:
    http://docs.saltstack.com/ref/states/highstate.html 
    '''
    return highstate 
