# postgresql operations specific to this project only

{% set project = pillar['project']['name'] %}


include:
  # install postgres or check that it's already setup
  - postgresql


{{ project }}-postgres-user:
  # create a postgres user and give permission to create databases 
  postgres_user.present:
    - name: {{ pillar['postgresql']['user'] }}
    - createdb: {{ pillar['postgresql']['createdb'] }}
    - password: {{ pillar['postgresql']['password'] }}
    - runas: postgres
    - require:
      - service: postgresql

{{ project }}-postgres-db:
  # create a database owned by the user created previously
  postgres_database.present:
    - name: {{ pillar['postgresql']['db'] }}
    - encoding: UTF8
    - lc_ctype: en_US.UTF8
    - lc_collate: en_US.UTF8
    - template: template0
    - owner: {{ pillar['postgresql']['user'] }}
    - runas: postgres
    - require:
        - postgres_user: {{ project }}-postgres-user
