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
##    Define argument and options specific to screen command.
##
##  Output:
##    SYSOUT - The command list with descriptions.
##
###############################################################################
function VirtDockerCmmdOptionsArgsDef () {
  echo 'Arg1 single "$PROJECT_NAME" "" required ""'
  echo '--dlwc single "attach" "" required ""'
}
###############################################################################
##
##  Purpose:
##    Describes purpose and arguments for the screen command.
##
##  Output:
##    SYSOUT - Help to use screen.
##
###############################################################################
function VirtCmmdHelpDisplay () {
  local -r commandName="`VirtDockerContainerCommandNameGet`"
cat <<COMMAND_HELP_Purpose

Create a new terminal window for each Docker command generated by the provided
dlw command.  The new terminal window is either added to an existing screen session
or a new one specified by SESSION_NAME. 

Usage: dlw $commandName [OPTIONS] DLW_COMMAND SESSION_NAME

  DLW_COMMAND: --dlwc={'attach'|'<dlwCommand>'}
          '<dlwCommand>'  Replace <dlwCommand> with one that keeps SYSIN open,
                            like 'start', 'run', 'attach', 'watch' ....  Should 
                            be enclosed in single/double quotes with appropriate 
                            escaping of potential inner quotes when inner quotes
                            specified.
  SESSION_NAME:  { '$PROJECT_NAME' | <name> }
                          Replace <name> with label that either uniquely selects
                            an existing screen session or will create a new one.
                            SESSTION_NAME is an alias for socket name:
                            '-S' option :: do not specify this linux screen option. 
COMMAND_HELP_Purpose
  HelpOptionHeading
  HelpNoExecuteDocker 'false'
  HelpShowDocker 'false'
  HelpHelpDisplay 'false'
  ScreenOptionsFormat
  return 0
}
###############################################################################
##
##  Purpose:
##    Obtain help text for the linux screen commmand.
##
##  Input:
##    None
##
##  Output:
##    SYSOUT - Help text describing only screen's options.
##
###############################################################################
function ScreenOptionsFormat () {
  function VirtOptionsExtractHelpDisplay () {
    screen --help
  }
  OptionsExtract 'screen'
  return 0
}
###############################################################################
##
##  Purpose:
##    Executes the provided dlw command to generate one or more Docker
##    commands.  Each of the Docker commands becomes the target command
##    for the screen utility.
##
##  Assume:
##    Since bash variable names are passed to this routine, these names
##    cannot overlap the variable names locally declared within the
##    scope of this routine or its decendents.
##
##  Input:
##    $1 - Variable name to an array whose values contain the label names
##         of the options and agruments appearing on the command line in the
##         order specified by it.
##    $2 - Variable name to an associative array whose key is either the
##         option or argument label and whose value represents the value
##         associated to that label.
##    $3 - dlw command to execute. Maps 1 to 1 onto with Docker command line.
##
##  Output:
##    SYSOUT - Packets containing attributes specific to a given Docker Target.
##         For example, Docker commands that operate on containers require a
##         Container GUID. In this situation, the packet will contain a
##         Container GUID field.
## 
###############################################################################
function VirtDockerTargetGenerate (){
  local -r optsArgListNm="$1"
  local -r optsArgMapNm="$2"
  local -r commandName="$3"
  local screenCmmd
  #  get the dlw command to execute
  AssociativeMapAssignIndirect "$optsArgMapNm" '--dlwc' 'screenCmmd'
  screenCmmd+=' '
  #  ensure dlw command isn't executed and request that the entire
  #  packet be forwarded to this pipeline so its attributes can
  #  be accessed to help assemble the linux screen command.
  screenCmmd="${screenCmmd/ / --dlwno-exec=true --dlwshow=packet }"
  local dockerPacket
  while read dockerPacket; do
    PipeScriptNotifyAbort "$dockerPacket"
    if ! PacketPreambleMatch "$dockerPacket"; then
      # not a packet - forward
      echo "$dockerPacket"
      continue
    fi
    # packet detected
    local -A dockerCmmdMap
    unset dockerCmmdMap
    local -A dockerCmmdMap
    PacketConvertToAssociativeMap "$dockerPacket" 'dockerCmmdMap'
    # does packet contain generated Docker command
    local dockerCmmd="${dockerCmmdMap['DockerCommand']}"
    if [ -z "$dockerCmmd" ]; then
      # packet doesn't contain a docker command :: forward it.
      echo "$dockerPacket"
      continue
    fi
    if [ -n "${dockerCmmdMap['ComponentName']}" ]; then
      # change the current packet's command context to reference 'screen' context.
      local componentContextPath="$COMPONENT_CAT_DIR/${dockerCmmdMap['ComponentName']}/context/$commandName"
    else
      # a command, like Watch, that will execute a dlw command as it's not target specific.
      # TODO: perhaps implement a project wide 'context' for non-targeted commands?  Might also want to implement inheritance mechanism for even targeted commands.
      local componentContextPath="$PROJECT_DIR/context/$commandName"
    fi    
    # reference docker command as 'ScreenCommand' attribute and add the new value of the ComponentContextPath
    # to the packet's end so it can override the initial value established by the dlw command.
    PacketAddFromStrings "$dockerPacket" 'ScreenCommand' "$dockerCmmd" 'ComponentContextPath' "$componentContextPath" 'dockerPacket'
    echo "$dockerPacket"
  done < <( eval dlw.sh $screenCmmd )
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
  echo 'PACKET_DOCKER_COMMAND ScreenCommand'
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
  echo '-S "`AssociativeMapAssignIndirect "$optsArgMapNm" 'Arg1'`" -X screen $DOCKER_CMMDLINE_OPTION -t "`if [ -n "$PACKET_COMPONENT_NAME" ]; then echo "$PACKET_COMPONENT_NAME"; else echo '"\'"'$( QuoteSingleReplace "$PACKET_DOCKER_COMMAND" ' ' )'"\'"'; fi`"  $PACKET_DOCKER_COMMAND'
  return 0
}
###############################################################################
##
##  Purpose:
##    Establish 'screen' as 'primary' command while assembling templates.
##
##  Input:
##    None
## 
##  Output:   
##    SYSOUT - Since the secondary command is already 'screen', output
##             a null string as the primary one.
##
###############################################################################
function VirtDockerCmmdExecPrimaryName () {
  echo ""
}
###############################################################################
##
##  Purpose:
##    Execute the linux screen command creating a new detached session (socket daemon) 
##    or if the session exists, simply add the each Docker command as a new
##    screen to the specified session.
##
##  Input:
##    $1 - dlw command to execute. Maps 1 to 1 onto with Docker command line.
## 
##  Output:   
##    When Success:
##       The screen with the given session name contains one or more windows
##       for containers with open STDIN streams.
##    When Failure: 
##      Issues an error messages written to SYSERR, then terminate the process.
##
###############################################################################
function VirtDockerCmmdExecute () {
  local screenCmmd="$5"
  # try running screen.  This will simply add more screen windows to an
  # existing session.  If the named session doesn't exist, it will fail,
  # then try executing it as deamon to create the session.
  eval $screenCmmd \>\/\dev\/\null\ \2\>\/\dev\/\null
  if [ "$?" -ne '0' ]; then
    screenCmmd="${screenCmmd/screen -S/screen -dmS}"
    screenCmmd="${screenCmmd/-X screen /}"
    eval $screenCmmd
  fi
}
###############################################################################
##
##  Purpose:
##    Configure container virtual function to report  implement 'screen' command.
##
###############################################################################
function VirtDockerContainerCommandNameGet () {
  echo 'screen'
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
