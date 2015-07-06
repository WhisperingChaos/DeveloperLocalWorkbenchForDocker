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
##    Configure container virtual functions to implement 'stop' command.
##
###############################################################################
##
function VirtDockerContainerCommandNameGet () {
  echo 'rm'
}
##############################################################################
##
##  Purpose:
##    Configure container virtual functions to implement 'rm' command.
##
#################################################################################
##
function VirtDockerCmmdOptionsArgsDef () {
  ComponentNmListArgument 'rm' ''
  ComponentVersionArgument
}
###############################################################################
##
##  Purpose:
##    Describes purpose and arguments for the 'help' command itself.
##
##  Outputs:
##    SYSOUT - The command list with descriptions.
##
###############################################################################
function VirtCmmdHelpDisplay () {
cat <<COMMAND_HELP_Purpose

Remove containers for targeted components.  Wraps Docker 'rm' command.

Usage: dlw rm [OPTIONS] TARGET 
COMMAND_HELP_Purpose
  HelpCommandTarget "Caution!"
  HelpOptionHeading
  HelpComponentVersion
  HelpNoExecuteDocker 'false'
  HelpShowDocker 'false'
  HelpHelpDisplay 'false'
  DockerOptionsFormat 'rm'
return 0
}
###############################################################################
##
##  Purpose:
##    Given one or more Component names, version scope and the desired 
##    command/operation to be executed against these Component(s), map each
##    Component to a Docker Target Concept.  A Docker Target Concept can
##    either be a Repository:tag (Image Name), Image GUID, or 
##    Container GUID.
##
##    Essentially this function converts the Docker Local Workbench
##    (dlw) Component concept into is associated Docker image or container
##    objects.  A dlw Component is a analogous to class/type definition
##    that can be instantiated as an executable object.  Given this definition,
##    a Component can be directly mapped to a Docker image (class/type)
##    and a Docker container (executable object).
##    
##  Assumption:
##    Since bash variable names are passed to this routine, these names
##    cannot overlap the variable names locally declared within the
##    scope of this routine or its decendents.
##
##  Inputs:
##    $1 - Variable name to an array whose values contain the label names
##         of the options and agruments appearing on the command line in the
##         order specified by it.
##    $2 - Variable name to an associative array whose key is either the
##         option or argument label and whose value represents the value
##         associated to that label.
##    $3 - dlw command to execute. Maps 1 to 1 onto with Docker command line.
## 
##  Return Code:     
##    When Failure: 
##      Indicates unknown parse state or token type.
##
###############################################################################
function VirtDockerTargetGenerate (){
  if ! DockerTargetContainerGUIDGenerate "$1" "$2" "$3" 'false' 'true' 'true' 'false'; then ScriptUnwind $LINENO "Unexpectd return code."; fi
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
