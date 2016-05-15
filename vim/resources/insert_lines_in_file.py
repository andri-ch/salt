#!/usr/bin/python

"""
This script inserts a bunch of lines in a file based on the position of a
known substring inside that file.
It is important the way you open the file, in text mode or binary mode.
"""

FILE = '/usr/share/vim/vim73/filetype.vim'
PATTERN = '" Nano'

### Open file in binary mode ###
with open(FILE, 'rb') as infile:
    # 'rb' -> open file in read binary mode, preserves newlines(\n)
    contents = infile.readlines()
    # .readlines() returns a list of lines, it is a one time only operation

line_index = 0

for index, line in enumerate(contents):
    if line.find(PATTERN) > -1:
        line_index = index
#        print(index)

# list.insert(index, object) -> insert object before index
contents.insert(line_index + 3, '" Nginx conf files; added by Andrei\n')
contents.insert(line_index + 4, "au BufRead,BufNewFile /etc/nginx/* if &ft == '' | setfiletype nginx | endif\n")
contents.insert(line_index + 5, "\n")

# prepare contents to be written to file, transform them into a stream(str..)
contents = ''.join(contents)

with open(FILE, 'wb') as outfile:
    outfile.write(contents)


#### Open file in text mode ###
#
#with open(FILE, 'r') as infile:
#    # 'r' -> open file in read text mode, doesn't preserve newlines(\n)
#    contents = infile.readlines()
#
#line_index = 0
#
#for index, line in enumerate(contents):
#    if line.find('" Nano') > -1:
#        line_index = index
#
## list.insert(index, object) -> insert object before index
#contents.insert(line_index + 3, '" Nginx conf files; added by Andrei')
#contents.insert(line_index + 4, "au BufRead,BufNewFile /etc/nginx/* if &ft == '' | setfiletype nginx | endif")
#contents.insert(line_index + 5, "")
#
#contents = '\n'.join(contents)
#
#with open(FILE, 'w') as outfile:
#    outfile.write(contents)

##################################################


# script can be stateful=True in sls files => returns result upon success
# the state line indicates that the script was run and changed state
# successfully

# writing the state line
print()          # an empty line here so the next line will be the last.
print("changed=yes comment='Pattern \"%s\" found on line with index %s'" % (PATTERN, line_index))
