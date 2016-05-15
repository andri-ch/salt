# this is a django related operations state file
# django & its deps are installed in venv.sls
# this file should be able to be run just by itself
# $: sudo salt 'minion_id' state.sls projects.[project].django

{% set project = pillar['project']['name'] %}
{% set bin = pillar['django']['virtualenv'] + '/bin' %}
{% set pip = bin + '/pip' %}
{% set python = bin + '/python' %}
{% set project_dir = pillar['django']['virtualenv'] + '/workspace/' + project + '/' + project %}



check_{{ project }}_virtualenv:
  # check that django venv exists -> all venvs have a bin/pip
  file.exists:
    - name: {{ pillar['django']['virtualenv'] }}/bin/pip


check_{{ project }}_requirements_installed:
  # at least South should be installed or
  # at least psycopg2 should be installed, as we work with psql all the time
  cmd.run:
    - name: {{ pip }} freeze | grep South 
    - require:
      - file: check_{{ project }}_virtualenv


{{ project }}_install_django:
# state that explicitly installs django, doesn't use a requirements file
  pip.installed:
    - name: django >= 1.6, <= 1.7
    - bin_env: {{ pillar['django']['virtualenv'] }}/bin/pip
    - require:
      - cmd: check_{{ project }}_requirements_installed


{{ project }}_create_django_workspace:
  file.directory:
    - name: {{ pillar['django']['virtualenv'] }}/workspace
    - user: {{ pillar['django']['user'] }}
    - require: 
      - pip: {{ project }}_install_django


check_{{ project }}_workspace:
  file.exists:
    - name: {{ pillar['django']['virtualenv'] }}/workspace


{{ project }}_django_startproject:
    # create a new django project
  cmd.run:
    - name: {{ pillar['django']['virtualenv'] }}/bin/django-admin.py startproject {{ project }}
    - cwd: {{ pillar['django']['virtualenv'] }}/workspace
    - require: 
      - file: check_{{ project }}_virtualenv
      - file: check_{{ project }}_workspace

#/var/www/venv/gs/.git:
## test state
#  git.present:
#    - user: www-data
{{ project }}_django_check_project_exists:
  # all projects have a settings.py so we check for that 
  file.exists:
    - name: {{ project_dir }}/settings.py

{{ project }}_django_dev_settings:
  # copy our development settings.py file
  file.managed:
    - name: {{ pillar['django']['virtualenv'] }}/workspace/{{ project }}/{{ project }}/settings_dev.py
    - source: salt://projects/{{ project }}/django/{{ pillar['django']['version'] }}/settings_dev.py
    - template: jinja
    - user: {{ pillar['django']['user'] }}
    - group: {{ pillar['django']['group'] }}
    - mode: 664
    - require:
      - file: {{ project }}_django_check_project_exists

{{ project }}_django_prod_settings:
  # copy our production settings.py file
  file.managed:
    - name: {{ pillar['django']['virtualenv'] }}/workspace/{{ project }}/{{ project }}/settings_prod.py
    - source: salt://projects/{{ project }}/django/{{ pillar['django']['version'] }}/settings_prod.py
    - template: jinja
    - user: {{ pillar['django']['user'] }}
    - group: {{ pillar['django']['group'] }}
    - mode: 664
    - require:
      #- file: {{ project }}_django_check_project_exists
      - file: {{ project }}_django_dev_settings


#{{ project }}_django_superuser:
#  module.run:
#    - django.createsuperuser 
#    - settings_module: {{ project_dir }}/settings_dev.py 
#    - user: {{ pillar['django']['django_admin'] }}
#    - email: {{ pillar['django']['django_admin_email'] }}
#    - require:
#      - file: {{ project }}_django_prod_settings


{{ project }}_django_syncdb:
  # ./manage.py syncdb
  # make cmd fail when exceptions are raised
  module.run:
    - name: django.syncdb 
    - settings_module: settings_dev
    # bin_env represents the path to virtualenv
    - bin_env: {{ pillar['django']['virtualenv'] }}
    # pythonpath represents the path to your project (folder that holds settings.py, etc.)
    #- pythonpath: {{ pillar['django']['virtualenv'] }}/workspace/{{ project }}
    - pythonpath: {{ project_dir }}
    - require: 
      - file: {{ project }}_django_prod_settings

#{{ project }}_django_syncdb:
#    # this command could be replaced by salt.states.django in the future
#  cmd.run:
#    - name: source {{ bin }}/activate && {{ python }} manage.py syncdb --settings={{ project }}.settings_dev.py
#    - cwd: {{ pillar['django']['virtualenv'] }}/workspace/{{ project }} 
#    - user: {{ pillar['django']['user'] }}
#    - group: {{ pillar['django']['group'] }}
#    - timeout: 20
#    - require: 
#      - file: {{ project }}_django_prod_settings

{{ project }}_add_gitignore:
  # add a .gitignore, we prepare for git VCS
  file.managed:
    - name: {{ pillar['django']['virtualenv'] }}/workspace/{{ project }}/.gitignore
    - source: salt://projects/gassrl/django/gitignore
    - user: {{ pillar['django']['user'] }}
    - group: {{ pillar['django']['group'] }}
    - require:
      - file: {{ project }}_django_prod_settings

{{ project }}_git_init:
  # initialize git & make first commit
  cmd.run:
    - name: git init && git add {{ project }} && git commit -m "initial deploy, db untainted"
    - cwd: {{ pillar['django']['virtualenv'] }}/workspace/{{ project }} 
    - user: {{ pillar['django']['user'] }}
    - group: {{ pillar['django']['group'] }}
    - timeout: 20
    - require: 
      - file: {{ project }}_django_prod_settings


