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
##    Configure container virtual functions to implement 'diff' command.
##
###############################################################################
##
function VirtDockerContainerCommandNameGet () {
  echo 'diff'
}
##############################################################################
function VirtDockerCmmdOptionsArgsDef () {
  ComponentNmListArgument 
  ComponentVersionArgument 'cur'
}
###############################################################################
function VirtCmmdHelpDisplay () {
cat <<COMMAND_HELP_Purpose

Inspect changes applied to container(s) derived from targeted components.  Wraps docker 'diff' command.

Usage: dlw diff [OPTIONS] TARGET 
COMMAND_HELP_Purpose
  HelpCommandTarget ' '
  HelpOptionHeading
  HelpComponentVersion 'cur'
  HelpNoExecuteDocker 'false'
  HelpShowDocker 'false'
  HelpHelpDisplay 'false'
  DockerOptionsFormat 'diff'
return 0
}
###############################################################################
function VirtDockerTargetGenerate (){
  if ! DockerTargetContainerGUIDGenerate "$1" "$2" "$3" 'false' 'true' 'true' 'false'; then ScriptUnwind $LINENO "Unexpectd return code."; fi
}
FunctionOverrideCommandGet
source "ArgumentsMainInclude.sh";
