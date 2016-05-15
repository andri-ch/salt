#!/bin/bash

echo "ALTER USER postgres PASSWORD 'blamblam12xc34';" | psql postgres

# writing the state line
echo  		# an empty line here so the next line will be the last.
echo "changed=yes comment='postgres role password updated'"
