# you can run this file with 
# `sudo salt 'localminion' state.top vim_top.sls`  , relative/abs paths don't work yet, top files need to be located at salt://

base:
   '*':
     - vim             # by default vim/init.sls
    
