# gassrl specific top.sls file
# apply it using state.top instead of state.highstate
# $: cp -v ./projects/gassrl/top.sls ./gassrl_top.sls
# $: sudo salt 'gassrl' state.top gassrl_top.sls

base:
#  '*':
#    - requirements.essential
#    - ssh
  'gassrl':
    - requirements.essential 
    - projects.gassrl.nginx
#    - example-project.ssh
    - projects.gassrl.postgresql
#    - example-project.local
#    - example-project.rabbitmq
    - projects.gassrl.venv
    - projects.gassrl.django
#    - example-project.uwsgi
    - projects.gassrl.supervisor
