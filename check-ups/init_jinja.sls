{# set address = 'www.alinia.ro' #}             # left for testing
{% for address in pillar['domains'] %}
check_{{ address }}:
  cmd.script:
    - name: "test_site_up {{ address }}"        # address here doesn't do anything, it's just for debugging
    - args: "{{ address }}"                     # instead, this address it is given as arg to the script
    - source: salt://check-ups/resources/test_site_up.py
    - stateful: true                            # script returns changed=yes only when the site it checks is down
    - timeout: 20 

## firing of events disabled because reactor system doesn't work well
#fire_{{ address }}_event:    
#  cmd.wait:                   # Run the given command only if its watch statement calls it
#    - name: 'salt "localminion" event.fire_master "id=localminion" "site_is_down"'          # len(tag) < 20 addr={{ address }}
#    - watch:                  # this is a must for cmd.wait, if state above changes something, run this state
#      - cmd: check_{{ address }}                # when this cmd changes the state, cmd.wait runs.

{% endfor %}

call_admin:
  cmd.wait_script:           # Download a script & execute it only if a watch(state of fct. watch) statement calls it.
    - name: 'make_call'
    - source: salt://check-ups/resources/twilio/make_call.py
    - watch: 
    {% for address in pillar['domains'] %}
      - cmd: check_{{ address }}          # only if this cmd changes the state, run the script
    {% endfor %}


# Left here for testing if sending sms works
#sms_admin:
#  cmd.wait_script:           # Download a script & execute it only if a watch(state of fct. watch) statement calls it.
#    - name: 'send_sms'
#    - args: " address "      # delete the double {} when state is commented out because Jinja would interfere otherwise
#    - source: salt://check-ups/resources/twilio/send_sms.py
#    - watch: 
#      - cmd: check_ address           # only if this cmd changes the state, run the script

