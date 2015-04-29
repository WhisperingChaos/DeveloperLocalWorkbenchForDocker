#!/bin/bash
###############################################################################
#
#  Purpose: 
#    Generic install script to facilitate encoding package installs.
#
#  Input:
#    $1 - Package name.
#
###############################################################################
if [ -z "$1" ]; then echo "Error: ${FUNCNAME}: Expects package name as first argument.">&2; fi
# Script is coupled with versionSpecifiers.sh to load environment
# variables that specify the package's version.
source versionSpecifiers.sh
# Certain installs may require preprocessing to prepare the package library
# for their inclusion.
if which "installPrep_${1}.sh"; then
  if ! "installPrep_${1}.sh"; then exit 1; fi
fi
# Use a simple mapping function to associate a package name to its version
# environment variable value.
# Translate package name characters that aren't valid for environment variable
# names.
EVIRONMENT_NAME_SUFFIX=$( echo "$1" | sed 's/[^a-zA-Z0-9]/_/g' )
eval COMPONENT_VERSION_SPEC=\"\$VERSION_${EVIRONMENT_NAME_SUFFIX}\"
# execute the install
apt-get install -y ${1}${COMPONENT_VERSION_SPEC}


