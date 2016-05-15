# this script makes sure that all the essential packages are installed
# run only this state file with 
# $: sudo salt '*' state.sls requirements.essential

build-essential:
  # useful to build debian packages (install new pkgs)
  pkg.installed

make:
  # useful when building some python packages - maybe wsgi, etc.
  pkg.installed

tree:
  # complementary to 'ls'
  pkg.installed

aptitude:
  # good, easy-to-use package manager
  pkg.installed

git:
  # the best VCS
  pkg:
    - installed

bzr:
  # preferred VCS
  pkg.installed

python-pip:
  # python package installer
  pkg.installed

virtualenvwrapper:
  # also installs python-virtualenv
  pkg.installed

python3.2:
  # used by virtualenv to create a python3 interpreter for django 1.6
  # could be very well replaced by python3.3
  pkg.installed:
    - pkgs:
      - python3.2
      - python3.2-dev
      # python3.2-dev provides all the header files needed by other programs

sqlite3:
  # useful if you create django apps that use sqlite3 engine
  pkg.installed:
    - pkgs:
      - sqlite3
      - sqlite3-doc
