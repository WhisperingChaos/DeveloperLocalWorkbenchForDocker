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
##    Configure container virtual functions to implement 'attach' command.
##
###############################################################################
##
###############################################################################
##
##  Purpose:
##    Define both the options and arguments accepted by attach command.
##    overriding the default settings for all container commands.
##
###############################################################################
function VirtDockerCmmdOptionsArgsDef () {
  ComponentNmListArgument "`VirtDockerContainerCommandNameGet`" "`VirtDockerContainerCompArgDefault 'value'`"
  ComponentVersionArgument 'cur'
  # by default don't execute the attach command.  Since dlw command execution occurs in a pipe, attach
  # doesn't make sense.
  echo '--dlwno-exec single true=EXIST=true "OptionsArgsBooleanVerify \<--dlwno-exec\>" required ""'
  # by default show the generated command(s)
  echo '--dlwshow single true=EXIST=true "ShowOptionVerify \<--dlwshow\>" required ""'
  echo '--dlwno-prereq single order=EXIST=true "ComponentNoPrereqVerify \<--dlwno-prereq\>" required ""'
  echo '--dlwign-state single false=EXIST=true "OptionsArgsBooleanVerify \<--dlwign-state\>" required ""'
}
###############################################################################
##
##  Purpose:
##    Describes purpose and arguments for container commands.
##
##  Output:
##    SYSOUT - The command list with descriptions.
##
###############################################################################
function VirtCmmdHelpDisplay () {
  local -r commandName="`VirtDockerContainerCommandNameGet`"
cat <<COMMAND_HELP_Purpose

Connect interactively to containers for targeted Components.  Must be used
with 'tmux' command in order to establish separate terminals for
attached each container.  Wraps docker '$commandName' command.

Usage: dlw $commandName [OPTIONS] TARGET

COMMAND_HELP_Purpose
  HelpCommandTarget "`VirtDockerContainerCompArgDefault 'description'`"
  HelpOptionHeading
  HelpComponentVersion 'cur'
  HelpComponentNoPrereq "$commandName" 'order'
  HelpIgnoreStateDocker 'false'
  HelpNoExecuteDocker 'false'
  HelpShowDocker 'true'
  HelpHelpDisplay 'true'
  DockerOptionsFormat "$commandName"
return 0
}

function VirtDockerContainerCommandNameGet () {
  echo 'attach'
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
    if [ "${dockerStatus:0:2}" == 'Up' ]; then
    return 0;
  fi
  return 1
}
FunctionOverrideCommandGet
source "ArgumentsMainInclude.sh";
