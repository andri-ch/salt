# gassrl specific top.sls file
# apply it using
# $:sudo salt 'gassrl' state.top projects.gassrl.top.sls
# if the minion id is 'gassrl'

base:
#  '*':
#    - requirements.essential
#    - ssh
  'gassrl':
    - projects.gassrl.nginx
#    - example-project.ssh
#    - example-project.postgresql
#    - example-project.local
#    - example-project.rabbitmq
#    - example-project.venv
#    - example-project.uwsgi
#    - example-project.nginx
