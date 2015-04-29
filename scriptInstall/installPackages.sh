#!/bin/bash
###############################################################################
#
#  Purpose: 
#    Install provided list of packages.
#  
#  Input:
#    $1-N - Package names to install
#
#  Output:
#    When failure:
#      Either the error code from failed install process or rm failure code
#
###############################################################################
  SCRIPT_DIR_INSTALLATION="`dirname "${BASH_SOURCE[0]}"`"
  # Resolve helper script names within same install directory of this module
  # before searching rest of the path.
  PATH=$SCRIPT_DIR_INSTALLATION:$PATH
  # Initialize ubuntu distribution library list
  apt-get update
  while [ "$#" -gt '0' ]; do
    # execute an install for package listed as an argument
    if ! install.sh "$1"; then exit; fi
    shift
  done
  # make install helper scripts invisible from this layer forward
  if [ -d "$SCRIPT_DIR_INSTALLATION" ] && [ "$SCRIPT_DIR_INSTALLATION" != '/' ]; then
    if ! rm -f -r "$SCRIPT_DIR_INSTALLATION"; then exit; fi
  fi
  

