# Django production settings for {{ pillar['project']['name'] }}.
from settings_dev import *

DEBUG = TEMPLATE_DEBUG = False


# by default, django sends emails to admins when code raises an unhandled exception
# also make sure that EMAIL_HOST is set to the proper hostname for your mail server.
# The following might also need to be set:
# EMAIL_HOST_USER = ''
# EMAIL_HOST_PASSWORD = ''
# EMAIL_PORT = ''
# EMAIL_USE_TLS = ''
ADMINS = (
    ('Andy', 'andreichiver@google.com'),
)

SEND_BROKEN_LINK_EMAILS = True


TEMPLATE_DIRS = (
    # Put strings here, like "/home/html/django_templates" or "C:/www/django/templates".
    # Always use forward slashes, even on Windows.
    # Don't forget to use absolute paths, not relative paths.
    # the following holds the 404 & 500 error pages
    #"/home/andrei/Envs/django_test/workspace/templates/",
    "{{ pillar['django']['virtualenv'] }}/workspace/{{ pillar['project']['name'] }}/templates/"
)

# SSL/HTTPS
# Use secure cookies => instruct browser to send cookies by default over HTTPS connections. This means sessions will not work over HTTP => redirect all HTTP traffic to HTTPS(usally at the webserver level, eg. Nginx, especially if Django uses a reverse proxy setup)
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True   # POST data won't be accepted over HTTP => redirect to HTTPS

