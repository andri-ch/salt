# vi: set ft=conf :

{% set project = pillar['project']['name'] %}


include:
  - nginx

nginx-conf-{{ project }}:
# copy nginx conf specific to this project
  file.managed:
    - name: /etc/nginx/sites-available/{{ project }}.conf
    - source: salt://projects/{{ project }}/nginx.conf
    - template: jinja
    - user: www-data
    - group: www-data
    - mode: 755
    - require:
      - pkg: nginx

# Symlink and thus enable the virtual host,
# link from sites-available to sites-enabled
nginx-enable-{{ project }}:
  file.symlink:
    - name: /etc/nginx/sites-enabled/{{ project }}.conf
    - target: /etc/nginx/sites-available/{{ project }}.conf
    - force: false
    - require:
      - file: nginx-conf-{{ project }}

reload-nginx-for-{{ project }}:
  service.running:
    - name: nginx
    - reload: True
    - require:
      - file: nginx-enable-{{ project }}
