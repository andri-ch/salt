#!py

# you can run only this state file with
# $: sudo salt '*' state.sls vim

# user = 'andrei'
# If using Vagrant to create VMs
user = 'vagrant'     

highstate = {}

# vim:
#   pkg:
#     - installed

highstate['vim'] = {
                'pkg': ['installed']
                }

highstate['copy_files'] = {
                'file': ['recurse',   # copy all from 'source' to 'name'
                            {'name': '/home/%s/.vim/' % user},
                            {'source': 'salt://vim/resources/vim'},
                            {'user': '%s' % user},
                            {'group': '%s' % user},
                            {'dirmode': 755},
                            {'filemode': 644},
                        ],
                }

#highstate['patch_filetype.vim'] = {
#                'file': ['patch',       # apply a patchfile using 'patch' binary
#                            {'name': '/usr/share/vim/vim73/filetype.vim'},         # file to be patched
#                            {'source': 'salt://vim/resources/usr_share_vim_vim73_filetype.vim-nginx.patch'},      # src of the patchfile
#                            {'hash': 'md5=800c4583a0cb72d44e7872bda82899de'},      # hash of the patched file
#                            {'dry_run_first': False},                              # disable safety checks, as hash is for local filetype.vimwhich most certainly differs from filetype.vim found on servers
#                            {'options': '--force'},                      # --force ->  don't ask questions, assume user knows what's doing
#                            {'require': [{'file':'copy_files'},
#                                        ]}
#                        ],
#                }

highstate['patch_filetype.vim'] = {
                'cmd': ['script',
                            {'source': 'salt://vim/resources/insert_lines_in_file.py'},
                            {'onlyif': 'ls /usr/share/vim/vim73/filetype.vim'},
                            {'stateful': True},
                            {'timeout': 10},
                            {'require': [{'file':'copy_files'},
                                        ]}
                        ],
                }


def run():
    return highstate
