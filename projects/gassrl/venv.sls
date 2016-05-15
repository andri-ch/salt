# this will create a virtualenv specifically for this project along with all 
# its dependencies
# $: sudo salt 'gassrl' state.sls projects.gassrl.venv

{% set project = pillar['project']['name'] %}

#include:
#  - nginx

{{ pillar['django']['virtualenvs_dir'] }}:
# we createe the system-wide directory for the virtual environments if it 
# doesn't exist.
  file.directory:
    - user: {{ pillar['django']['user'] }}
    - group: {{ pillar['django']['group'] }}
#    - require:
#      - file: /var/www
#      - user: www-data

#
### python2.7 virtualenv:
#
#{{ project }}_create_django_virtualenv:
#  virtualenv.managed:
#    - name: {{ pillar['django']['virtualenv'] }}
#    - no_site_packages: True              
#    # no_site_packages: True is the default for newer virtualenv
#    - clear: True
#    - distribute: True
#    # distribute: True means pip will manage the virtualenv
#    - requirements: salt://projects/{{ project }}/requirements.txt
#    # if a requirements exists, virtualenv uses pip.installed which 
#    # uses system pip by default -> pip for python2.7, as salt doesn't 
#    # support python3.x
#    - relocatable: True
#    - python: python2.7
#    #- runas: www-data
#    # runas is deprecated, use user instead
#    #- user: www-data
#    - user: www-data
#    - require:
#      - file: /var/www/venv


### python3.x virtualenv
# comment out these states and uncomment the above for django in a python2.7 
# venv

{{ project }}_create_django_virtualenv:
# python3.x needs a python3.2 or python3.3 system-wide package and 
# python3.x-dev header files package!
  virtualenv.managed:
    - name: {{ pillar['django']['virtualenv'] }}
    - no_site_packages: True              
    # no_site_packages: True is the default for newer virtualenv
    #- clear: True
    # clear means to wipe everything if the env already exists. Dangerous!
    - distribute: True
    # distribute: True means pip will manage the virtualenv
    - relocatable: True
    - python: python{{ pillar['django']['virtualenv_python'] }}
    #- requirements: salt://projects/{{ project }}/requirements.txt
    # requirements can't be used by python3 venv, for now
    - user: {{ pillar['django']['user'] }}
    - require:
      - file: {{ pillar['django']['virtualenvs_dir'] }}


{{ project }}_virtualenv_requirements:
  # this state can take a lot of time, based on what the requirements are.
  # One solution would be to deploy your requirements as wheels.
  pip.installed:
    #- name: greenlet eventlet gunicorn psycopg2 south
    - requirements: salt://projects/{{ project }}/requirements_py3.txt
    - bin_env: {{ pillar['django']['virtualenv'] }}/bin/pip 
    - require:
      - virtualenv: {{ project }}_create_django_virtualenv


{{ project }}_install_django:
# state that explicitly installs django, doesn't use a requirements file
  pip.installed:
    - name: django >= 1.6, <= 1.7
    - bin_env: {{ pillar['django']['virtualenv'] }}/bin/pip
    - require:
      - pip: {{ project }}_virtualenv_requirements

# the above states are obsolete/or can be kept if installing a django in a 
# python2.7 venv
### end python3.x virtualenv
#


{{ project }}_create_django_workspace:
  file.directory:
    - name: {{ pillar['django']['virtualenv'] }}/workspace
    - user: {{ pillar['django']['user'] }}
    - require: 
      - virtualenv: {{ project }}_create_django_virtualenv
