#!/bin/bash
source "MessageInclude.sh";
source "ArgumentsGetInclude.sh";
source "ArrayMapTestInclude.sh";
source "ComponentListVerifyInclude.sh";
source "ArgumentsDockerVerifyInclude.sh";
source "VirtCmmdInterface.sh";
source "VirtDockerInterface.sh";
source "VirtDockerContainerInterface.sh";
source "VirtDockerReportingInterface.sh";
source "VirtDockerReportingCmmdMultiInterface.sh";
source "PacketInclude.sh";
##############################################################################
##
##  Purpose:
##    Configure container virtual functions to implement 'top' command.
##
#################################################################################
##
##############################################################################
function VirtDockerReportingCommandNameGet () {
  echo 'top'
}
function VirtDockerContainerCommandNameGet () {
  VirtDockerReportingCommandNameGet
}
function VirtDockerContainerOrderingGet () {
  # order of prerequsites as they are, not in reverse
  echo 'true'
}
function VirtDockerReportingHeadingRegex () {
  echo '^UID|LABEL\ *PID\ '
  return 0
}
FunctionOverrideCommandGet
source "ArgumentsMainInclude.sh";
