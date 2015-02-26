#!/bin/bash
source "MessageInclude.sh";
source "ArgumentsGetInclude.sh";
source "ArrayMapTestInclude.sh";
source "ComponentListVerifyInclude.sh";
source "ArgumentsDockerVerifyInclude.sh";
source "VirtCmmdInterface.sh";
source "VirtDockerInterface.sh";
source "VirtDockerCmmdSingle.sh";
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
  echo '--dlwc single "ps" "" required ""'
  echo '--dlwno-exec single true=EXIST=true "OptionsArgsBooleanVerify \<--dlwno-exec\>" required ""'
  echo '--dlwshow single true=EXIST=true "ShowOptionVerify \<--dlwshow\>" required ""'
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

Periodically execute a dlw command in a 'watch' terminal window.  Should
be employed as command to 'dlw screen' command. 

Usage: dlw $commandName [OPTIONS] DLW_COMMAND

  DLW_COMMAND: --dlwc={'watch --dlwc=ps'|'<dlwCommand>'}
          '<dlwCommand>'  Replace <dlwCommand> with one that makes sense for
                            linux watch like 'ps', 'images', 'build'... .  Should 
                            be enclosed in single/double quotes with appropriate 
                            escaping of potential inner quotes when inner quotes
                            specified.

COMMAND_HELP_Purpose
  HelpOptionHeading
  HelpNoExecuteDocker 'true'
  HelpShowDocker 'true'
  HelpHelpDisplay 'false'
  WatchOptionsFormat
  return 0
}
###############################################################################
##
##  Purpose:
##    Obtain help text for the linux watch commmand.
##
##  Input:
##    None
##
##  Output:
##    SYSOUT - Help text describing only watch's options.
##
###############################################################################
function WatchOptionsFormat () {
  function VirtOptionsExtractHelpDisplay () {
    watch --help
  }
  OptionsExtract 'watch'
  return 0
}
###############################################################################
function VirtDockerTargetGenerate (){
  return 0
}
###############################################################################
function VirtDockerCmmdAssembleSingle () {
  local -r optArgMapNm="$1"
  local -r commandNm="$2"
  local -r commandOpts="$3"
  local dlwCommand
  AssociativeMapAssignIndirect "$optArgMapNm" '--dlwc' 'dlwCommand'
  echo "watch $commandOpts '$SCRIPT_DIR_DLW/dlw.sh' $dlwCommand"
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
  echo "watch"
}
VirtDockerCmmdExecutePacketForward () {
  echo 'false'
}
function VirtCmmdExecute (){
  VirtDockerMain "$1" "$2" 'watch'
}
FunctionOverrideCommandGet
source "ArgumentsMainInclude.sh";
