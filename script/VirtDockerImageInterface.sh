#!/bin/bash
###############################################################################
##
##    Section: Abstract Interface:
##      Declare abstract interface for run & create image commands.
##
###############################################################################
##
###############################################################################
##
##  Purpose:
##    Define both the options and arguments accepted by the specific
##    image command.
##
###############################################################################
function VirtDockerImageArgOptionDef () {
  ScriptUnwind $LINENO "Please override: $FUNCNAME".
}
###############################################################################
##
##  Purpose:
##    Identifies specific command by outputting its dlw name.
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
function VirtDockerImageCommandNameGet () {
  ScriptUnwind $LINENO "Please override: $FUNCNAME".
}
###############################################################################
##
##  Purpose:
##    Produce help usage section for given image command.
##
##  Input:
##    None
##    
##  Output:
##    When Successful:
##      SYSOUT - Help Usage: text.
##
###############################################################################
function VirtDockerImageHelpUsage () {
  ScriptUnwind $LINENO "Please override: $FUNCNAME".
}
###############################################################################
##
##  Purpose:
##    Provides help text for option(s) specific to a given command.
##
##  Input:
##    None
##    
##  Output:
##    When Successful:
##      SYSOUT - Properly formatted text explaining new options.
##
###############################################################################
function VirtDockerImageHelpOptions () {
  ScriptUnwind $LINENO "Please override: $FUNCNAME".
}
###############################################################################
##
##    Section: Shared Impementation:
##      Implementation of virtual functions common to commands
##      targeting image create & run.
##
###############################################################################
##
##############################################################################
##
##  Purpose:
##    Override virtual function to set default configuration option ensure 
##    that component hive exists for image commands.
##
##  Input:
##    $0 - Name of running script that included this configuration interface.
##
##  Output:
##    When Failure: 
##      SYSERR - Reflect message indicating reason for error
##
#################################################################################
function VirtCmmdConfigSetDefault () {
  if ! [ -d  "$COMPONENT_CAT_DIR" ]; then
    ScriptUnwind $LINENO "Missing Component directory: '$COMPONENT_CAT_DIR'."
  fi
  return 0
}
###############################################################################
##
##  Purpose:
##    Define the common options and arguments accepted by the image
##    commands.
##
##  Input:
##    VirtDockerImageArgOptionDef - Callback function to obtain arg/option
##    definitions unique to a given image command.
##
##  Outputs:
##    SYSOUT - option arg entries whose format conforms to the format
##       defined by VirtCmmdOptionsArgsDef
##
###############################################################################
function VirtDockerCmmdOptionsArgsDef () {
  ComponentNmListArgument "`VirtDockerImageCommandNameGet`" 'all'
  ComponentVersionArgument 'cur'
  echo '--dlwno-prereq single false=EXIST=order "ComponentNoPrereqVerify \<--dlwno-prereq\>" required ""'
  VirtDockerImageArgOptionDef
  return 0
}
###############################################################################
##
##  Purpose:
##    Describes the purpose and arguments for the common arguments supported
##    by image commands.
##
##  Input:
##    VirtDockerImageHelpUsage - callback function providing help text for
##         a command's usage section.
##    VirtDockerImageHelpOptions - callback function providing help text
##         describing options unique to a given command.
##    VirtDockerImageCommandNameGet - callback function providing the dlw
##        command name.
##
##  Output:
##    SYSOUT - The command help text.
##
###############################################################################
function VirtCmmdHelpDisplay () {
  VirtDockerImageHelpUsage
  HelpCommandTarget
  HelpOptionHeading
  HelpComponentVersion 'cur'
  VirtDockerImageHelpOptions
  HelpComponentNoPrereq 'container actuation' 'false'
  HelpNoExecuteDocker 'false'
  HelpShowDocker 'false'
  HelpHelpDisplay 'false'
  DockerOptionsFormat "`VirtDockerImageCommandNameGet`"
  return 0
}
###############################################################################
##
##  Purpose:
##    Given one or more Component names, version scope and the desired 
##    command/operation to be executed against these Component(s), map each
##    Component to a Docker Image GUID.
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
##    VirtDockerImageNoPrereqSetting - A callback function that provides the
##         noPrereq setting required by this routine.
## 
##  Return Code:     
##    When Success: 
##      SYSOUT - provides .
##    When Failure: 
##      SYSERR - provides .
##
###############################################################################
function VirtDockerTargetGenerate (){
  local -r optsArgListNm="$1"
  local -r optsArgMapNm="$2"
  local -r commandNm="$3"
  local -r noPrereq="`AssociativeMapAssignIndirect "$optsArgMapNm" '--dlwno-prereq'`"
  local dependGraph
  local excludePrereq
  NoPrereqSetting "$noPrereq" 'true' 'dependGraph' 'excludePrereq'
  if ! DockerTargetImageGUIDGenerate "$1" "$2" "$3" "$dependGraph" 'true' "$excludePrereq"; then ScriptUnwind $LINENO "Unexpectd return code."; fi
}
###############################################################################
##
##  Purpose:
##    Provides a means of extending the bash variable name-value pairs 
##    defined during template resolution.
##
##    Default implementation does nothing.
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
  echo 'PACKET_IMAGE_GUID ImageGUID'
  return 0
}
###############################################################################
##
##  Purpose:
##    Define build command template.  The 'build' type supported creates an
##    image with whose name is identical to the component name and whose tag
##    is defined as ":latest".  The build context is defined as the component's
##    local build context directory.
##
###############################################################################
function VirtDockerCmmdAssembleTemplate () {
  echo '$DOCKER_CMMDLINE_OPTION  $PACKET_IMAGE_GUID  $DOCKER_CMMDLINE_COMMAND $DOCKER_CMMDLINE_ARG'
  return 0
}
###############################################################################
function VirtDockerCmmdExecutePacketForward () {
  echo 'false'
  return 0
}
###############################################################################
##
##  Purpose:
##    Implements the dlw image command.
##
##  Assumption:
##    Since bash variable names are passed to this routine, these names
##    cannot overlap the variable names locally declared within the
##    scope of this routine or is decendents.
##
##  Inputs:
##    $1 - Variable name to an array whose values contain the label names
##         of the options and agruments appearing on the command line in the
##         order specified by it.
##    $2 - Variable name to an associative array whose key is either the
##         option or argument label and whose value represents the value
##         associated to that label.
##    VirtDockerImageCommandNameGet - callback function to obtain the Docker
##         command to be generated.
##    
##  Outputs:
##    When Successful:
##      SYSOUT - Reflects output from execution of Docker command or the 
##         set of Docker commands to execute.
##    When Failure: 
##      SYSERR - Displays informative error message.
##
###############################################################################
function VirtCmmdExecute (){
  VirtDockerMain "$1" "$2" "`VirtDockerImageCommandNameGet`"
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
