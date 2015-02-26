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
##    Configure container virtual functions to implement 'kill' command.
##
#################################################################################
##
##############################################################################
function VirtDockerReportingCommandNameGet () {
  echo 'top'
}
###############################################################################
##
##  Purpose:
##    Describes purpose and arguments for reporting commands.
##
###############################################################################
function VirtCmmdHelpDisplay () {
local -r commandName="`VirtDockerReportingCommandNameGet`"
ComponentNmListArgument "$commandName" 'all'

cat <<COMMAND_HELP_Purpose

Report on targeted Components' container(s).  Wraps docker '$commandName' command.

Usage: dlw $commandName [OPTIONS] TARGET 

COMMAND_HELP_Purpose
  HelpCommandTarget
  HelpOptionHeading
  HelpComponentVersion 'cur'
  HelpIgnoreStateDocker 'false'
  HelpNoExecuteDocker 'false'
  HelpShowDocker 'false'
  HelpColumnSelectExclude 'ComponentName/COMPONENT/15,ContainerGUID/CONTAINER ID/12'
  HelpColumnHeadingRemove 'false'
  HelpHelpDisplay 'false'
  DockerOptionsFormat "$commandName"
  function psOptionsFormat () {
    function VirtOptionsExtractHelpDisplay () {
      ps --help
    }
    OptionsExtract 'ps'
  }
  psOptionsFormat
}
##############################################################################
function VirtDockerReportingHeadingRegex () {
  echo '^UID|LABEL\ *PID\ '
  return 0
}
FunctionOverrideCommandGet
source "ArgumentsMainInclude.sh";
