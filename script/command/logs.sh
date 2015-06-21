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
##    Configure container virtual functions to implement 'logs' command.
##
###############################################################################
##
###############################################################################
##
##  Purpose:
##    Define both the options and arguments accepted by logs command.
##    overriding the default settings for all container commands.
##
###############################################################################
function VirtDockerCmmdOptionsArgsDef () {
  ComponentNmListArgument "`VirtDockerContainerCommandNameGet`" "`VirtDockerContainerCompArgDefault 'value'`"
  ComponentVersionArgument 'cur'
  # by default don't execute the logs command.  Since dlw command execution occurs in a pipe, logs
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

Connect or snapshot a container's STDERR and STDOUT stream for targeted Components.
Must be used with 'tmux' command in order to establish separate terminals for
each container.  Wraps Docker '$commandName' command.

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
  echo 'logs'
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
###############################################################################
# 
# The MIT License (MIT)
# Copyright (c) 2014-2015 Richard Moyse License@Moyse.US
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
###############################################################################
#
# Docker and the Docker logo are trademarks or registered trademarks of Docker, Inc.
# in the United States and/or other countries. Docker, Inc. and other parties
# may also have trademark rights in other terms used herein.
#
###############################################################################
