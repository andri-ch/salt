"""
Django development settings for {{ pillar['project']['name'] }} project.

This file is used to override default settings during development phase.
"""

# import default settings
from settings import *


# Application definition
# former INSTALLED_APPS when django is installed
DEFAULT_APPS = INSTALLED_APPS
#DEFAULT_APPS = (
#    'django.contrib.admin',
#    'django.contrib.auth',
#    'django.contrib.contenttypes',
#    'django.contrib.sessions',
#    'django.contrib.messages',
#    'django.contrib.staticfiles',
#)

THIRD_PARTY_APPS =  {{ pillar['django']['third_party_apps'] }}

LOCAL_APPS = ()

# really important
INSTALLED_APPS = DEFAULT_APPS + THIRD_PARTY_APPS + LOCAL_APPS


# Database
# https://docs.djangoproject.com/en/1.6/ref/settings/#databases

DATABASES = {
    'default': {
        'ENGINE': os.path.join(BASE_DIR, "{{ pillar['postgresql']['engine'] }}"),
        'NAME': "{{ pillar['postgresql']['db'] }}",
        'USER': "{{ pillar['postgresql']['user'] }}",
        'PASSWORD': "{{ pillar['postgresql']['password'] }}",
        'HOST': "{{ pillar['postgresql']['engine'] }}",
        'PORT': "{{ pillar['postgresql']['port'] }}",
    }
}

# Internationalization
# https://docs.djangoproject.com/en/1.6/topics/i18n/

TIME_ZONE = 'Europe/Bucharest'
