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

##############################################################################
##
##  Purpose:
##    Configure container virtual functions to implement 'kill' command.
##
#################################################################################
##
##############################################################################
function VirtDockerContainerCommandNameGet () {
  echo 'kill'
}
##############################################################################
function VirtDockerContainerOrderingGet () {
  echo 'reverse'
}
##############################################################################
function VirtContainerStateFilterApply () {
  local -r dockerStatus="$1"
  if [ "${dockerStatus:0:2}" == 'Up' ] && ! [[ "$dockerStatus" =~ .*\(Paused\) ]]; then
    return 0;
  fi
  return 1
}
FunctionOverrideCommandGet
source "ArgumentsMainInclude.sh";
