sms_admin:
  cmd.script:                                              # Download a script & execute it
    - name: 'check_sites_and_send_sms'
    - args: "{{ pillar['domains']|join(' ') }}"            # after Jinja rendering: args: www.alinia.ro www.gassrl.ro ...
    - source: salt://check-ups/resources/test_site_up_sms.py
    - stateful: true
    - timeout: 20
