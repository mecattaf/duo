#!/bin/bash
# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

# User specific environment and startup programs

# Auto-start scroll via UWSM on tty1
if [[ $(tty) = /dev/tty1 ]]; then
    exec uwsm start scroll
fi
