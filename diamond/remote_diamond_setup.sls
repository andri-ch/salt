#!py


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

#highstate = {'include': ['lvm/init'] }                       # include: list of files to include
                        # lvm/init was included just to make available state 'vgscan'

### INIT ###
highstate = {}


highstate['install_diamond.deb'] = {
                'pkg': ['installed',
                            {'sources': [{'diamond': 'salt://diamond/resources/diamond.deb'},
                                        ]},
                       ],                           # comma(,) left because other states can be added to highstate structure
                }

highstate['configure_diamond'] = {
                'file': ['managed',
                            {'name': '/etc/diamond/diamond.conf'},
                            {'source': 'salt://diamond/resources/diamond.conf'},
                            {'require': [{'pkg': 'install_diamond.deb'},
                                        ]}
                        ],                         
                }

highstate['configure_collectors'] = {
                'file': ['recurse',  # Recurse through a dir on the master and copy said dir over to the specified path.
                            {'name': '/etc/diamond/collectors/'},
                            {'source': 'salt://diamond/resources/collectors'},
                            {'user': 'root'},
                            {'group': 'root'},
                            {'dir_mode': 755},
                            {'file_mode': 644},
                            {'require': [{'file': 'configure_diamond'},
                                        ]}
                        ],                         
                }

# Some diamond collectors need additional setup in order to function:
# Eg.:
# NginxCollector -> /etc/nginx/conf.d/diamond.conf 
# PostgresqlCollector -> psycopg2 package installed system-wide
# The additional setup will be done only the specific collectors are present.

### BEGIN postgresql additional setup ###
highstate['postgresql_tweaks'] = {
                'cmd': ['run',
                            {'name': 'pip install psycopg2'},        # sudo apt-get install python-psycopg2 
                            {'onlyif': 'ls /etc/diamond/collectors/PostgresqlCollector.conf'},
                            {'require': [{'file': 'configure_collectors'},
                                        ]}
                       ],
                } 

highstate['create_role_password'] = {
                'cmd': ['script',
                            {'name': '/usr/local/bin/create_role_password.sh'},
                            {'source': 'salt://diamond/resources/postgres/create_role_password.sh'},
                            {'user': 'postgres'},
                            {'shell': '/bin/bash'},
                            {'stateful': True},
                            {'require': [{'cmd': 'postgresql_tweaks'},
                                        ]}
                       ],
                }
highstate['del_create_password_script'] = {
                'file': ['absent',
                            {'name': '/usr/local/bin/create_role_password.sh'},
                            {'require': [{'cmd': 'create_role_password'},
                                        ]}
                        ],
                }
### END postgresql additional setup ###

### BEGIN nginx additional setup ###
highstate['nginx_tweaks'] = { # find if nginx was compiled with http_stub_status_module which is needed for statistics
                'cmd': ['run',
                            {'name': '2>&1 nginx -V | tr -- - "\n" | grep http_stub_status_module'},  # nginx uses stderr to output 
                            {'onlyif': 'ls /etc/diamond/collectors/NginxCollector.conf'},
                            {'require': [{'file': 'configure_collectors'},
                                        ]}
                       ],
                } 
highstate['setup_status_page'] = { # create a virtual host that serves the page with nginx stats
                'file': ['managed',
                            {'name': '/etc/nginx/conf.d/diamond_monitoring.conf'},       
                            {'source': 'salt://diamond/resources/nginx/diamond_monitoring.conf'},
                            {'require': [{'cmd': 'nginx_tweaks'},
                                        ]}
                       ],
                } 
highstate['restart_nginx'] = {              # restart to reread *.conf files
                'service': ['running',
                                {'name': 'nginx'},
                                {'reload': True},
                                {'require': [{'file': 'setup_status_page'},
                                            ]}
                           ],
                }
# TODO: detect if nginx has an apparmor profile and in what state, complain/enforce mode
# You can do that with 'sudo aa-status | grep /usr/sbin/nginx' , regex for '\d+ are in enforce mode'
# Then add '/etc/nginx/conf.d/diamond_monitoring.conf r,' to /etc/apparmor.d/usr.sbin.nginx
# and reload the kernel module with apparmor_parser /etc/apparmor.d/usr.sbin.nginx
### END nginx additional setup ###


highstate['start_diamond'] = {
                'service': ['running',                          # Verify that the service is running 
                            {'name': 'diamond'},
                            {'sig': 'diamond'},
                            {'require': [{'file': 'configure_collectors'},
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
