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
##    Configure container virtual functions to implement 'port' command.
##
#################################################################################
##
##############################################################################
function VirtDockerReportingCommandNameGet () {
  echo 'port'
}
function VirtDockerContainerCommandNameGet () {
  VirtDockerReportingCommandNameGet
}
function VirtDockerContainerOrderingGet () {
  # order of prerequsites as they are, not in reverse
  echo 'true'
}
###############################################################################
function VirtDockerCmmdExecute () {
  local -r dockerCmmd="$5"
  function VirtDockerCmmdExecuteFilter () {
    local output='NullOutput'
    local nullOutput='true'
    while read output; do
      if $nullOutput; then
        # echo a report heading
        echo 'PORT MAP'
        nullOutput='false'
      fi
      echo "$output"
    done
    if $nullOutput; then echo 'NULL_OUTPUT_GENERATED'; fi
    return 0
  }
  # run the port command, convert general error message to a reporting value
  # allow STDOUT to continue to next piped process without modification.
  eval $dockerCmmd \2\>\&\1 \>\ \>\(  \VirtDockerCmmdExecuteFilter \)
  return 0;
}
##############################################################################
function VirtDockerReportingHeadingRegex () {
  echo '^PORT\ MAP'
  return 0
}
FunctionOverrideCommandGet
source "ArgumentsMainInclude.sh";
