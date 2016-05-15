#!/usr/bin/python

# Download the library from twilio.com/docs/libraries
from twilio.rest import TwilioRestClient


# Get these credentials from http://twilio.com/user/account
# Test auth
#account_sid = "XXXXXXXXXX"
#auth_token = "XXXXXXXXXX"

# Live auth    -> needed to SMS to your public, vodafone number
account_sid = "XXXXXXXXXX"
auth_token = "XXXXXXXXXX"

client = TwilioRestClient(account_sid, auth_token)
# Make the call to="+XXXXXXXXXX", from_="XXXXXXXXXX"
call = client.calls.create(to="+4072XXXXXXXXXX",     # Any phone number
                           from_="2XXXXXXXXXX",    # Must be a valid Twilio number
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
