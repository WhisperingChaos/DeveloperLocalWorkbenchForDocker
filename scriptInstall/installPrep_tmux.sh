#!/bin/bash
###############################################################################
#
#  Purpose: Add very recent percise backported version of tmux
#
###############################################################################
# attepted to use trusted precise backported version but couldn't get it wwork.
# this untrusted ppa made it easily possible.
echo 'deb http://ppa.launchpad.net/pi-rho/dev/ubuntu precise main '>>/etc/apt/sources.list
echo 'deb-src http://ppa.launchpad.net/pi-rho/dev/ubuntu precise main'>>/etc/apt/sources.list
if ! apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 779C27D7; then exit 1; fi
if ! apt-get update; then exit 1; fi

