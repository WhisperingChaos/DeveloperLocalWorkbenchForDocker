#!/bin/bash
###############################################################################
##
##    Section: Abstract Interface:
##      Declare abstract interface for container commands like 'start', 'kill'...
##
###############################################################################
##
###############################################################################
##
##  Purpose:
##    Identifies specific container command by outputting its dlw name.
##
##  Input:
##    None
##    
##  Output:
##    When Successful:
##      SYSOUT - Name of dlw command.
##    When Failure: 
##      SYSERR - Displays informative error message.
##
###############################################################################
function VirtDockerContainerCommandNameGet () {
  ScriptUnwind $LINENO "Please override: $FUNCNAME".
}
###############################################################################
##
##  Purpose:
##    Determines the type of dependency graph navigation for the container
##    command given the dependencies reflect the run/start command perspective.
##
##  Input:
##    None
##    
##  Output:
##    When Successful:
##      SYSOUT:
##         'true'    - Use run/start command perspective.
##         'false'   - Ordering adheres order of targets in argument list.
##         'reverse' - Reverse run/start command perspective
##    When Failure: 
##      SYSERR - Displays informative error message.
##
###############################################################################
function VirtDockerContainerOrderingGet () {
  ScriptUnwind $LINENO "Please override: $FUNCNAME".
}
###############################################################################
##
##  Purpose:
##    Determines the type of dependency graph navigation for the container
##    command given the dependencies reflect the run/start command perspective.
##
##  Input:
##    $1 - Determines if description or value of the default Component argument
##         is written to SYSOUT.
##         'value' - write default value to SYSOUT
##         otherwise - write its description.
##    
##  Output:
##    When Successful:
##      SYSOUT:
##         Default Component argument value or its description.
##    When Failure: 
##      SYSERR - Displays informative error message.
##
###############################################################################
function VirtDockerContainerCompArgDefault () {
  ScriptUnwind $LINENO "Please override: $FUNCNAME".
}
###############################################################################
##
##    Section: Shared Impementation:
##      Implementation of virtual functions common to commands
##      targeting containers.
##
###############################################################################
##
##############################################################################
##
##  Purpose:
##    Default implementation for this virtual function requires user to
##    specify targeted Component names or 'all', as it is safer to require
##    a target than defaulting to 'all'.
##
#################################################################################
function VirtDockerContainerCompArgDefault () {
  if [ "$1" == 'value' ]; then echo ''; else echo 'Caution!'; fi 
}
###############################################################################
##
##  Purpose:
##    Define both the options and arguments accepted by container commands.
##
###############################################################################
function VirtDockerCmmdOptionsArgsDef () {
  ComponentNmListArgument "`VirtDockerContainerCommandNameGet`" "`VirtDockerContainerCompArgDefault 'value'`"
  ComponentVersionArgument 'cur'
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

${commandName^} containers for targeted Components.  Wraps Docker '$commandName' command.

Usage: dlw $commandName [OPTIONS] TARGET

COMMAND_HELP_Purpose
  HelpCommandTarget "`VirtDockerContainerCompArgDefault 'description'`"
  HelpOptionHeading
  HelpComponentVersion 'cur'
  HelpComponentNoPrereq "$commandName" 'order'
  HelpIgnoreStateDocker 'false'
  HelpNoExecuteDocker 'false'
  HelpShowDocker 'false'
  HelpHelpDisplay 'false'
  DockerOptionsFormat "$commandName"
return 0
}
###############################################################################
##
##  Purpose:
##    Map Component names and  version scope to their associated 
##    Container GUID.
##
###############################################################################
function VirtDockerTargetGenerate (){
  local -r optsArgListNm="$1"
  local -r optsArgMapNm="$2"
  local -r commandNm="$3"
  # Interpert ordering option to sequence Docker container commands so the
  # command is more likely to succeed.
  local dependGraph
  local excludePrereq
  NoPrereqSetting "`AssociativeMapAssignIndirect "$optsArgMapNm" '--dlwno-prereq'`" "`VirtDockerContainerOrderingGet`" 'dependGraph' 'excludePrereq'
  # Determine if state filtering should be applied.
  local stateFilterApply
  AssociativeMapAssignIndirect "$optsArgMapNm" '--dlwign-state' 'stateFilterApply'
  if $stateFilterApply; then stateFilterApply='false'; else stateFilterApply='true'; fi 
  if ! DockerTargetContainerGUIDGenerate "$1" "$2" "$3" "$dependGraph" 'true' "$excludePrereq" "$stateFilterApply"; then
    ScriptUnwind $LINENO "Failure while generating Container GUID targets"
  fi
}
###############################################################################
##
##  Purpose:
##    Provides a means of extending the bash variable name-value pairs 
##    defined during template resolution.
##
##  Input:
##    $1 - dlw command to execute. Maps 1 to 1 onto with Docker command line.
## 
##  Output:   
##    When Success:
##       SYSOUT - Each record contains the desired bash varialble name
##         seperated by whitespace from the packet field name that
##         refers to the desired field value to be assigned to the 
##         bash variable name.
##    When Failure: 
##      Issues an error messages written to SYSERR, then terminate the process.
##
###############################################################################
VirtDockerCmmdAssembleTemplateResolvePacketField () {
  echo 'PACKET_CONTAINER_GUID ContainerGUID'
  return 0
}
###############################################################################
##
##  Purpose:
##    Define container command template.  Container commands typically accept
##    options followed by the container GUID.
##
###############################################################################
function VirtDockerCmmdAssembleTemplate () {
  echo '$DOCKER_CMMDLINE_OPTION $PACKET_CONTAINER_GUID'
  return 0
}
###############################################################################
##
##  Purpose:
##    Container commands do not require forwarding packets.
##
##  Input:
##    none
## 
##  Output:
##    'false' - do not forward command packet
## 
###############################################################################
function VirtDockerCmmdExecutePacketForward () {
  echo 'false'
}
###############################################################################
##
##  Purpose:
##    Starts the Virtual Docker pipline to generate Docker container 
##    commands.
##
##  Assumption:
##    Since bash variable names are passed to this routine, these names
##    cannot overlap the variable names locally declared within the
##    scope of this routine or is decendents.
##
##  Input:
##    $1 - Variable name to an array whose values contain the label names
##         of the options and agruments appearing on the command line in the
##         order specified by it.
##    $2 - Variable name to an associative array whose key is either the
##         option or argument label and whose value represents the value
##         associated to that label.
##    VirtDockerContainerCommandNameGet - Virtual callback mechanism to obtain
##         the dlw command name. Maps 1 to 1 onto with Docker command line.
##    
##  Output:
##    When Successful:
##      SYSOUT - Docker and dlw pipeline informational output.
##    When Failure: 
##      SYSERR - Docker and dlw pipeline error output.
##
###############################################################################
function VirtCmmdExecute (){
  local -r commandName="`VirtDockerContainerCommandNameGet`"
  VirtDockerMain "$1" "$2" "$commandName"
}
FunctionOverrideIncludeGet
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
