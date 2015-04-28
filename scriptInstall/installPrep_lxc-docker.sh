#!/bin/bash
###############################################################################
#
#  Purpose: Install Docker Daemon from ubuntu distribution libraries.
#
###############################################################################
# Install secure protocol to enable secure package updates.
install.sh 'apt-transport-https'
# Install docker package key and distribution directory.
if ! apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9; then exit 1; fi
if ! sh -c "echo deb https://get.docker.com/ubuntu docker main > /etc/apt/sources.list.d/docker.list"; then exit 1; fi
if ! apt-get update; then exit 1; fi

