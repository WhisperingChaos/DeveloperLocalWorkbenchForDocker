#!/bin/bash
source "MessageInclude.sh";
source "ArgumentsGetInclude.sh";
source "ArrayMapTestInclude.sh";
source "ComponentListVerifyInclude.sh";
source "ArgumentsDockerVerifyInclude.sh";
source "VirtCmmdInterface.sh";
source "VirtDockerInterface.sh";
source "VirtDockerImageInterface.sh";
source "PacketInclude.sh";
###############################################################################
##
##  Purpose:
##    Define both the options and arguments accepted by the specific
##    image command.
##
###############################################################################
function VirtDockerImageArgOptionDef () {
  # create uses only all common arguments/options.
  return 0
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
  echo 'create'
  return 0
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
cat <<COMMAND_HELP_Purpose

Create container for targeted component(s).  Wraps docker 'create' command.

Usage: dlw create [OPTIONS] TARGET 
COMMAND_HELP_Purpose
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
  # create uses only all common arguments/options.
  return 0
}
FunctionOverrideCommandGet
source "ArgumentsMainInclude.sh";
