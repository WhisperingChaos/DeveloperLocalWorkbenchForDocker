#!/bin/bash
source "MessageInclude.sh";
source "ArgumentsGetInclude.sh";
source "ArrayMapTestInclude.sh";
source "ComponentListVerifyInclude.sh";
source "ArgumentsDockerVerifyInclude.sh";
source "VirtCmmdInterface.sh";
source "VirtDockerInterface.sh";
source "VirtDockerContainerInterface.sh";
source "PacketInclude.sh";
###############################################################################
##
##  Purpose:
##    Configure container virtual functions to implement 'start' command.
##
###############################################################################
##
function VirtDockerContainerCommandNameGet () {
  echo 'start'
}
###############################################################################
function VirtDockerContainerOrderingGet () {
  echo 'true'
}
###############################################################################
function VirtDockerContainerCompArgDefault () {
  if [ "$1" == 'value' ]; then echo 'all'; else echo 'Default behavior.'; fi 
}
##############################################################################
function VirtContainerStateFilterApply () {
  local -r dockerStatus="$1"
    if [ "${dockerStatus:0:2}" == '  ' ] || [ "${dockerStatus:0:6}" == 'Exited' ] ; then
    return 0;
  fi
  return 1
}
FunctionOverrideCommandGet
source "ArgumentsMainInclude.sh";
