# nginx global configuration
# setup for particular sites will be done elsewhere (in site's own 
# salt folder) 

nginx:
  pkg.installed

nginx-service:
  service:
    - name: nginx
    - running
    - enable: True
    - reload: True
    - watch:
      #- file: /etc/nginx/nginx.conf
      - file: /etc/nginx/conf.d/
    - require:
      - pkg: nginx

# for earlier versions of nginx, a different nginx.conf file is used
# think about this: either put jinja vars(using grains) in nginx.conf
# to differentiate between nginx versions, setups, etc. or make different
# nginx.conf files
#
#{% if grains['osrelease'] == '11.10' %}
#/etc/nginx/nginx.conf:
#  file.managed:
#    - source: salt://nginx/nginx.conf
#    - user: root
#    - mode: 400
#    - template: jinja
#    - require:
#      - pkg: nginx
#      - user: nginx
#{% endif %}


#
# nginx version 1.1.19 has 
# nginx/sites-available
#       sites-enabled
# and /var/www/ operates under user 'www-data' instead of user 'nginx'
#
#
/etc/nginx/conf.d/:
  file.recurse:
    - source: salt://nginx/conf.d

disable-nginx-default:
  file.absent:
    - name: /etc/nginx/sites-enabled/default
    - require:
      - pkg: nginx

www-data:
  user.present:
    - home: /var/www
    - require:
      #- pkg: bash
      - pkg: nginx

/var/www:
  file.directory:
    - user: www-data
    - group: www-data
    - require:
      - user: www-data
      - pkg: nginx
        
/etc/nginx/sites-available:
  file.directory:
    - user: root
    - mode: 755
    - require:
      - pkg: nginx

/etc/nginx/sites-enabled:
  file.directory:
    - user: root
    - mode: 755
    - require:
      - pkg: nginx


# include supervisor installation here because it supervises gunicorn 
# http server
#supervisor:
#  pip.installed

#launch_supervisor:
#  service.running:
#    - name: supervisor
#    - require: 
#      - pip: supervisor

