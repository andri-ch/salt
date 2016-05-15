# installs postgresql client, server, etc.
# this state file uses ubuntu 12.04 pkg names
# show what this state file will do:
# $: sudo salt '*' state.show_sls postgresql

postgresql_dependencies:
  pkg.installed:
    - pkgs:
      # PostgreSQL C client library
      - libpq5                                    
      - ssl-cert
      # multiple versions of clients can be installed at the same time
      - postgresql-client-common
      # the actual DB client
      - postgresql-client-9.1          
      # manages multiple versions of postgres servers and maintains multiple clusters at the same time 
      - postgresql-common          
      # the actual DB server
      - postgresql-9.1 
      

postgresql:
  # metapackage, installs the stable postgresql, be it 9.1, etc.
  pkg:
    - installed
    - require: 
      - pkg: postgresql_dependencies
  service.running:
    - watch:
      - file: /etc/postgresql/9.1/main/pg_hba.conf
    - require: 
      - pkg: postgresql
    
pg_hba.conf:
  # put our customized postgres config file
  file.managed:
    - name: /etc/postgresql/9.1/main/pg_hba.conf
    - source: salt://postgresql/pg_hba.conf
    - user: postgres
    - group: postgres
    - mode: 644
    - require:
      - pkg: postgresql

#
### psycopg2_dependencies
#
# install dependencies for psycopg2 python DB adapter, used by django;
# we install them only once, when postgresql is installed, such that 
# same deps will be used for all psycopg2 installed in virtualenvs.

python-dev:
  pkg:
    - installed

libpq-dev:
  pkg.installed

postgresql-server-dev-9.1:
  pkg:
    - installed
    - require:
       - pkg: postgresql 

#
### end psycopg2_dependencies
#
