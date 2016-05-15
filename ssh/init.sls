# Write what is the outcome of executing this sls file

### Create user ###
andrei:
  group.present:                    # fct. 'present' of 'group' state 
    - gid: 1000                     # fct. kwd arg.
#      - system: True                # choose GID between FIRST_SYSTEM_GID and LAST_SYSTEM_GID 
  user.present:                     # 'present' fct. of state named 'user'
    - uid: 1000
    - system: True
    - groups: ["andrei"]            # a list of groups
    - home: /home/andrei
    - shell: /bin/bash
    - password: "h9YnFeheJntJE"     # hashed password
    - require:
      - group: andrei

# maybe a user can be declared simpler:
# andrei:
#   user.present:
#     - uid: 1000
#     - gid: 1000
#     - home: /home/andrei
#     - password: "hashed_password"
#     - shell: /bin/bash

###  Give sudo rights  ###
{% set users = ['andrei'] %}
{% for user in users %}
  # create /etc/sudoers.d/username
  file.managed:                     
    - name: /etc/sudoers.d/{{ user }}   
    - source: salt://ssh/sudoers_template 
    - user: root
    - group: root
    - mode: 440
    - template: jinja
    - defaults:                         # default context passed to the template 
    #- context: 
        username: {{ user }}
    - require:
      - user: {{ user }}                
  # check /etc/sudoers.d/username file syntax with visudo
  cmd.run:                     
    - name: visudo -c -f /etc/sudoers.d/{{ user }}    # cmd to execute
    - user: root
    - cwd: /
    - shell: /bin/bash
    - require: 
      - file: /etc/sudoers.d/{{ user }}              
    - watch:
      - file: /etc/sudoers.d/{{ user }}             
{% endfor %}

### Install ssh server ###
openssh-server:                     # ID declaration
  pkg:                              # state declaration, they are not used with a '-'
    - installed                     # function
  service.running:                  # running is a function
    - name: ssh                     # name is a function arg
    - watch:                        # requisite declaration
      - file: /etc/ssh/sshd_config

/etc/ssh/sshd_config:
  file.managed:                         # file.managed function
    - source: salt://ssh/sshd_config    # source is a kwd arg for managed fct.
    - user: root                        # user is kwd arg for managed fct
    - group: root
    - mode: 644
    - require:                      # requisite declaration 
      - pkg: openssh-server
      - file: pub_key       

pub_key:
  file.managed:
   - name: /home/andrei/.ssh/authorized_keys
   - source: salt://ssh/authorized_keys
   - user: andrei
   - group: andrei
   - mode: 600
   - require:
     - user: andrei
     - file.directory: /home/andrei/.ssh

/home/andrei/.ssh:
  file.directory:
    - user: andrei
    - group: andrei                 # defaults to minion's group 
    - mode: 700
    - require:
      - user: andrei









