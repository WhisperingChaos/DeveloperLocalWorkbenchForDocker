#!/bin/bash
source "MessageInclude.sh";
source "ArgumentsGetInclude.sh";
source "ArrayMapTestInclude.sh";
source "VirtCmmdInterface.sh";
###############################################################################
##
##  Purpose:
##    Insure dlw.sh has established a valid path to the command directory.
##
##  Input:
##    $0 - Name of running script that included this configuration interface.
##
##  Output:
##    When Failure: 
##      SYSERR - Reflect message indicating reason for error
##
#################################################################################
function VirtCmmdConfigSetDefault (){
  return 0
}
###############################################################################
##
##  Purpose:
##    Define both the options and arguments accepted by the 'help' command.
##
###############################################################################
function VirtCmmdOptionsArgsDef (){
cat <<OPTIONARGS
--dlwdepend single false=EXIST=true "OptionsArgsBooleanVerify \\<--dlwdepend\\>" required ""
--dlwlicense single false=EXIST=true "OptionsArgsBooleanVerify \\<--dlwlicense\\>" required ""
--dlwbugs single false=EXIST=true "OptionsArgsBooleanVerify \\<--dlwbugs\\>" required ""
OPTIONARGS
return 0
}
###############################################################################
##
##  Purpose:
##    Describes purpose and arguments for the 'version' command.
##
##  Outputs:
##    SYSOUT - The command list with descriptions.
##
###############################################################################
function VirtCmmdHelpDisplay () {
  cat <<COMMAND_HELP_HELP

Provide version and dependency info for dlw command.

Usage: dlw version [OPTIONS]

    --dlwdepend=false    Include known dependencies.
    --dlwlicense=false   Show licensing information.
    --dlwbugs=false      Where to report bugs and enhancements.
COMMAND_HELP_HELP
return 0
}
###############################################################################
##
##  Purpose:
##    Implements the dlw help command. It will either list all commands
##    dlw or provide specifie Docker Local Workbench.
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
##    
##  Outputs:
##    When Successful:
##      SYSOUT - Displays helpful documentation.
##    When Failure: 
##      SYSERR - Displays informative error message.
##
###############################################################################
function VirtCmmdExecute (){
  local argOptList="$1"
  local argOptMap="$2"
  local -r showDepend="`AssociativeMapAssignIndirect "$argOptMap" '--dlwdepend'`"
  local -r showLicense="`AssociativeMapAssignIndirect "$argOptMap" '--dlwlicense'`"
  local -r showBugs="`AssociativeMapAssignIndirect "$argOptMap" '--dlwbugs'`"
  echo "Version: dlw (docker local workbench): 0.5"
  if $showDepend; then 
    echo
    echo "Depends on: Docker: version: 1.3.x"
    echo "Depends on: Bash:   version: 4.2.25(1)-release"
    echo "Depends on: Screen: version: 4.00.03jw4 (FAU) 2-May-06"
  fi
  if $showLicense; then
    echo
    echo "License: The MIT License (MIT): http://opensource.org/licenses/MIT" 
    echo "License: Copyright (c) 2015 Richard Moyse License@Moyse.US"
  fi
  if $showBugs; then
    echo
    echo "Bugs: GitHub: https://github.com/WhisperingChaos/DockerLocalWorkbench" 
  fi
}
source "ArgumentsMainInclude.sh";
