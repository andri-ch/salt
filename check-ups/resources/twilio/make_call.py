#!/usr/bin/python

# Download the library from twilio.com/docs/libraries
from twilio.rest import TwilioRestClient


# Get these credentials from http://twilio.com/user/account
# Test auth
#account_sid = "AC43244174ff176d0d6b2e60e96a019f1b"
#auth_token = "f9f0914c762476af7639014f816941ae"

# Live auth    -> needed to SMS to your public, vodafone number
account_sid = "AC506d760aa5394ffbbfe9cf91eb0e841e"
auth_token = "4a949a6676e4d77846906add36439667"

client = TwilioRestClient(account_sid, auth_token)
# Make the call to="+40729814308", from_="2315773230"
call = client.calls.create(to="+40729814308",     # Any phone number
                           from_="2315773230",    # Must be a valid Twilio number
                           url="http://twimlets.com/holdmusic?Bucket=com.twilio.music.ambient",
                           timeout=10)
# for docs about .create(), check:
# https://twilio-python.readthedocs.org/en/latest/api/rest/resources.html#twilio.rest.resources.Calls.create

# url - is the HTTP URL of the TwiML file that Twilio will fetch
# when the call is answered.
# timeout - The integer number of seconds that Twilio should allow the phone to
# ring before assuming there is no answer.

# By default, your application does not get any notification when a call is
# complete, if the line is busy, or if no one answers. But you can get
# notified if you give status_callback as arg. to .create().


### SALT STACK ADAPTED ###

# script can be stateful=true in sls files => returns result upon success
# the state line indicates that the script was run and changed state
# successfully

print
print("changed=yes comment='call.sid: %s'" % call.sid)
