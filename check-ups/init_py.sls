#!py


# because grains module is not available by default, like it is for pydsl, 
# jinja, etc. renderers, we make a dirty grains import:
import salt
grains = salt.loader.grains({'grain': '', 'id':'', 'extension_modules':''})
# loader.grains() is a fct. that needs a dict with those keys as argument
# 'id':'' -> on minion on which this script is executed

### Create a sls file data structure ###
'''
highstate var. below must be a friendly state.highstate data structure that 
follows these standards:
    http://docs.saltstack.com/ref/states/highstate.html 
'''   

### INIT ###
highstate = {}

highstate['check_alinia.ro'] = {
                'cmd': ['script',
                            {'name': "test_site_up.py"},          
                            # I can pass as many args to script using 'args', check cmd.script module which underlies cmd.script state;
                            # Ref: https://github.com/saltstack/salt/blob/develop/salt/states/cmd.py
                            {args: grains['domains']},
                            # The name can be the source or the source value can be defined. Here, the source is renamed with name provided
                            {'source': 'salt://check-ups/resources/test_site_up.py'},
                            #{'template': 'jinja'},
                            {'stateful': True},
                            {'timeout': 20},
                        ]
                }

# TODO: make site name to be specified here and jinja rendered into the script above

# salt-master will react based on his rector config by running a reactor sls file 
# that will trigger state.highstate on minion where diamond will be installed.
#highstate['fire_deb_built_event'] = {
#                'cmd': ['run',
#                            {'name': 'salt "localminion" event.fire_master id="localminion" "diamond.deb built"'},
#                            {'require': [{'cmd': 'copy_deb_to_file_server'},
#                                        ]}
#                       ],
#                }
 

def run():
    '''
    This fct is mandatory when using "py" renderer. Must return a friendly
    state.highstate data structure that follows these standards:
    http://docs.saltstack.com/ref/states/highstate.html 
    '''
    return highstate 
