#!/usr/bin/python


# Script designed to be used by Salt Stack #

# shrink default partition non-interactively using fdisk, this is to be run
# after the filesystem has been shrunk.
# However, if using fdisk, first you need to delete it, then recreate it with
# the new size.

# Unfortunately, fdisk, when run non-interactively, doesn't work well, it needs
# a timeout between each command given, so python version is to be used.

# script is using jinja template notation:
#fdisk /dev/xvdb <<EOF
#d 1
#n
#p
#1
#
#
#+2520M
#EOF

# d 1   => delete partition number 1
# n     => add a new partition
# remember there's an invisible newline "\n" char at the end of every row
# p     => it will be a primary partition
# 1     => make it the first partition
# empty lines mean 'choose default'
# +1500M, for eg., denotes the size of partition, check out `man fdisk` for units' notation
# w     => write to partition table on disk and exit


# writing the state line
#echo  # an empty line here so the next line will be the last.
#echo "changed=yes comment='partition shrunk'"


### Python version ###

import subprocess
import time
from subprocess import PIPE, STDOUT

sp = subprocess.Popen(["fdisk", "{{ hdd }}"], bufsize=1, stdin=PIPE, stdout=PIPE, stderr=STDOUT)
# bufsize=1 means line buffered, bufsize=0 means no I/O buffering

### testing fdisk behaviour ###
#sp.stdin.write("v\n")
#time.sleep(0.5)
#sp.stdin.write("p\n")
#time.sleep(0.5)
#sp.stdin.write("q\n")          # quit fdisk without saving changes to partition table
#o = sp.stdout.read()
#print(o)

### Create new partition table ###
# to create new partition table, you have to  delete existing partitions
# A sequence of fdisk cmds is needed to delete 2 partitions(in case this script
# is rerun) or just a single partition: d\n1\nd\n.
sp.stdin.write("d\n")            # delete partition
time.sleep(0.5)
sp.stdin.write("1\n")            # choose part 1 to delete(if there are more than one)
time.sleep(0.5)
sp.stdin.write("d\n")            # delete partition 2, if any(script is rerun after errors)
time.sleep(0.5)
sp.stdin.write("n\n")            # add a new partition
time.sleep(0.5)
sp.stdin.write("p\n")            # it will be a primary partition
time.sleep(0.5)
sp.stdin.write("1\n")            # make it the first partition
time.sleep(0.5)
sp.stdin.write("\n")             # default starting sector of the partition
time.sleep(0.5)
sp.stdin.write("{{ size }}\n")             # last sector of the partition or size of partition in mega, gigabytes
time.sleep(0.5)
sp.stdin.write("p\n")           # print partition table
time.sleep(0.5)
#sp.stdin.write("w\n")           # write changes to disk
#o = sp.stdout.read()             # read until EOF
#print(o)

### extend above cmd sequence ###
### Create a second partition of type Linux LVM ###
sp.stdin.write("n\n")
time.sleep(0.5)
sp.stdin.write("p\n")
time.sleep(0.5)
sp.stdin.write("2\n")
time.sleep(0.5)
sp.stdin.write("\n")             # choose defalt first sector of the partition
time.sleep(0.5)
sp.stdin.write("\n")             # choose defalt last sector of the partition
time.sleep(0.5)
sp.stdin.write("p\n")
time.sleep(0.5)
sp.stdin.write("t\n")            # change partition system id/type
time.sleep(0.5)
sp.stdin.write("2\n")            # chose partition 2 to change
time.sleep(0.5)
sp.stdin.write("8e\n")           # make it of type Linux LVM
time.sleep(0.5)
sp.stdin.write("p\n")            # print partition table
time.sleep(0.5)
sp.stdin.write("w\n")            # write changes to disk and exit

o = sp.stdout.read()             # read output of fdisk in response to cmds written above


# writing the state line
print             # an empty line here so the next line will be the last. Don't use print() for empty lines
print("changed=yes comment='original partition shrunk, created second one of type Linux LVM'")
