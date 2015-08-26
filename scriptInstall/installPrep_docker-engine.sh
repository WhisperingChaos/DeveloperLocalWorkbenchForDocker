#!/bin/bash
###############################################################################
#
#  Purpose: Install Docker Daemon from ubuntu distribution libraries.
#
###############################################################################
# Install secure protocol to enable secure package updates.
install.sh 'apt-transport-https'
# Install docker package key and distribution directory.
if ! apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D; then exit 1; fi
if ! sh -c "echo deb https://apt.dockerproject.org/repo ubuntu-precise main > /etc/apt/sources.list.d/docker.list"; then exit 1; fi
if ! apt-get update; then exit 1; fi

