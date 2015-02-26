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
##    Configure container virtual functions to implement 'restart' command.
##
#################################################################################
##
function VirtDockerContainerCommandNameGet () {
  echo 'restart'
}
#################################################################################
function VirtDockerContainerOrderingGet () {
  echo 'true'
}
##############################################################################
function VirtContainerStateFilterApply () {
  local -r dockerStatus="$1"
  if [ "${dockerStatus:0:2}" == 'Up' ] && ! [[ "$dockerStatus" =~ .*\(Paused\) ]]; then
    return 0;
  fi
  if [ "${dockerStatus:0:2}" == '  ' ] || [ "${dockerStatus:0:6}" == 'Exited' ] ; then
    # restart acts as start
    return 0;
  fi
  return 1
}
FunctionOverrideCommandGet
source "ArgumentsMainInclude.sh";
