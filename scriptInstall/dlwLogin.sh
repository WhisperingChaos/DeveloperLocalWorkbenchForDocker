#!/bin/bash
###############################################################################
#
#  Purpose: 
#    Ehance the typical login process to adapt the 'dlw' container account's
#    UID and GID list so it matches/extends the external ones provided when the
#    container was initially created (docker create/run).
#
#  Inputs:
#    1.  ASSUME_UID - Environment variable potentially set with external
#          account's (account outside container) UID during
#          'docker run/create'
#    2.  ASSUME_GID_LIST - Environment variable potentially set with external
#          account's (account outside container) GID list during
#          'docker run/create'
#    
###############################################################################
  if ! [ -e "${BASH_SOURCE[0]}.FirstTimeCompleted" ]; then
    userUID_GID_Reassign.sh 'dlw' "$ASSUME_UID" "$ASSUME_GID_LIST"
    touch "${BASH_SOURCE[0]}.FirstTimeCompleted"
  fi
  login dlw
