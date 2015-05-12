#!/bin/bash
###############################################################################
#
#  Purpose: 
#    Provide username, password, and group settings for dlw user.
#  
#  Input:
#    $1 - Request name.
#
#  Output:
#    When failure:
#      Either the error code from failed install process or rm failure code
#
###############################################################################
if   [ "$1" == 'adduser' ]; then
  echo '--disabled-password --gecos -- dlw'
elif [ "$1" == 'passwd'  ]; then
  # Remove password for dlw.
  echo '-d dlw'
elif [ "$1" == 'gpasswd' ]; then
  # Associate dlw to docker group to enable dlw execution without specifying 'sudo'.
  echo '-a dlw docker'
else
  echo "Error: $0: Argument value: '$1' not supported."
  exit 1
fi 
exit 0

