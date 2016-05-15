# supervisor daemon that can manage gunicorn http server instances

{% set project = pillar['project']['name'] %}


check_supervisor:
  # check supervisor is globally installed and it is running as a service
  # this step is required if I want to run this sls file alone
  service.running:
    - name: supervisor

## add some jinja if/else to set the http_server, one of gunicorn or uwsgi
# gunicorn for python2.7, uwsgi for python3.x. 
{% if pillar['django']['virtualenv_python'] >= 3 %} 
{%    set http_server = uwsgi %}
{% else %}
{%    set http_server = gunicorn %}
{% endif %}

{{ project }}_supervisor_conf:
  file.managed:
    - name: /etc/supervisor/conf.d/{{ project }}_{{ http_server }}.conf
    - source: salt://projects/{{ project }}/supervisor_{{ http_server }}.conf
    # cofig files always end in *.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - service: check_supervisor

reload_supervisor:
  # every time we add/change a config file
  service.runnig:
    - name: supervisor
    - reload: True
    - require:
      - file: {{ project }}_supervisor_conf
