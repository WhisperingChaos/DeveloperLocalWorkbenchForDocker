#!/bin/bash
source "MessageInclude.sh";
source "ArgumentsGetInclude.sh";
source "ArrayMapTestInclude.sh";
source "ComponentListVerifyInclude.sh";
source "ArgumentsDockerVerifyInclude.sh";
source "VirtCmmdInterface.sh";
source "VirtDockerInterface.sh";
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
###############################################################################
function VirtDockerCmmdExecute () {
  local -r dockerCmmd="$5"
  function VirtDockerCmmdExecuteFilter () {
    local output='NullOutput'
    local nullOutput='true'
    while read output; do
      echo "$output"
      nullOutput='false'
    done
#    if $nullOutput; then echo ''; fi
    return 0
  }
  # generate a heading for the port map field
  echo 'I FILE'
  # run the port command, convert general error message to a reporting value
  # allow STDOUT to continue to next piped process without modification.
  eval $dockerCmmd \2\>\&\1 \>\ \>\(  \VirtDockerCmmdExecuteFilter \)
  return 0;
}
##############################################################################
function VirtDockerReportingHeadingRegex () {
  echo '^I\ FILE'
  return 0
}
FunctionOverrideCommandGet
source "ArgumentsMainInclude.sh";
