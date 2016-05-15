#!/usr/bin/python

# script written with python2.7 in mind

import functools
import httplib
import urllib2
import BaseHTTPServer    # useful to get the server error codes' explanation


class BoundHTTPHandler(urllib2.HTTPHandler):
    '''
    Creates an HTTP connection with a source address which you can specify
    if you have multiple interfaces/IPs.
    '''
    def __init__(self, source_address=None, debuglevel=0):
        urllib2.HTTPHandler.__init__(self, debuglevel)
        self.http_class = functools.partial(httplib.HTTPConnection,
                                            source_address=source_address)

    def http_open(self, req):
        return self.do_open(self.http_class, req)


"""
This gives us a custom urllib2.HTTPHandler implementation that is
source_address aware. We can add it to a new urllib2.OpenerDirector and
install it as the default opener (for future urlopen() calls) with the
following code:
"""
#handler = BoundHTTPHandler(source_address=('10.178.200.66', 0))
# 10.178.200.66 is a RS internal network, not connected to internet
handler = BoundHTTPHandler(source_address=('50.56.180.183', 0))               # source addr of the client
opener = urllib2.build_opener(handler)
urllib2.install_opener(opener)


### SALT STACK ADAPTED ###
# the salt sls file assigns a name for this script of the form:
# test_www.alinia.ro
# so we can get the website's address to test from the filename!
#address = __file__.split('_')[1]

address = "{{ pillar['domains'] }}"
##########################


# How to get www.alinia.ro since we don't have dns on RS internal network?
#req = urllib2.Request('http://10.178.200.148:80/admin/')

# Make a request to the internet available address:
#req = urllib2.Request('http://50.56.180.243:80/admin/')

# Make a request, using the domain name:
#req = urllib2.Request('http://www.alinia.ro')
req = urllib2.Request('http://' + address)
message = ''
try:
    response = urllib2.urlopen(req)
#    print("Server url: %s \nHeaders: %s\nBody: %s\n" % (response.geturl(), response.info(), response.read()))
    message = "Site %s is up" % response.geturl()
except urllib2.HTTPError as e:
#    print(e.code, BaseHTTPServer.BaseHTTPRequestHandler.responses[e.code])
    # .responses is an 'error code: error explanation' mapping
    message = "%s: %s" % (e.code, BaseHTTPServer.BaseHTTPRequestHandler.responses[e.code])
#    if hasattr(e, 'reason'):
#        print(e.reason)

#print(message)


### SALT STACK ADAPTED ###

# script can be stateful=True in sls files => returns result upon success
# the state line indicates that the script was run and changed state
# successfully

# writing the state line
#print          # an empty line here so the next line will be the last.
print("changed=yes comment='%s'" % message)         # salt stack CLI returner will assign this to 'stdout'

print
print("changed=yes comment='checked server'")
