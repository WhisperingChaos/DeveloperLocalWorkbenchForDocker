#!/bin/bash
###############################################################################
#
#  Purpose: 
#    Install one or more users.
#  
#  Input:
#    $1-N - Names of users to install/
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
  if which "installUser_${1}.sh"; then
    echo "Error: $0: Missing user configuration script: 'installUser_${1}.sh'."
  fi
  # Initialize user.
  while [ "$#" -gt '0' ]; do
    # execute an install for package listed as an argument
    addOpts="$(installUser_${1}.sh 'adduser')"
    if [ "$?" -ne '0' ];   then exit 0; fi
    if ! adduser $addOpts; then exit 0; fi
    passwdOpts="$(installUser_${1}.sh 'passwd')"
    if [ "$?" -ne '0' ];     then exit 0; fi
    if ! passwd $passwdOpts; then exit 0; fi
    while read groupList; do
      if ! gpasswd $groupList; then exit 0; fi
    done < <( if ! installUser_${1}.sh 'gpasswd'; then exit 1; fi  )
    shift
  done

exit 0

