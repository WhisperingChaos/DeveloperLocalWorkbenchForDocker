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
  echo "Version: dlw (developer local workbench): 0.6"
  if $showDepend; then 
    echo
    echo "Depends on: Docker:   version: `read version < <(docker version); echo "$version"|sed 's/Client version: \([^.]*\.[^.]*\).*/\1/'`.x"
    echo "Depends on: GNU bash: version: `read version < <(bash --version); echo "$version"|sed -r 's/GNU bash[, ]+version[ ]+([^.]+\.[^.]+[^ ]+).*/\1/'`"
    echo "Depends on: tmux:     version: `read version < <(tmux -V); echo "$version"|sed -r 's/tmux[ ]+([^.]+\.+[^ ]+).*/\1/'`"
  fi
  if $showLicense; then
    echo
    echo "License: The MIT License (MIT): http://opensource.org/licenses/MIT" 
    echo "License: Copyright (c) 2014-2015 Richard Moyse License@Moyse.US"
  fi
  if $showBugs; then
    echo
    echo "Bugs: GitHub: https://github.com/WhisperingChaos/DevelperLocalWorkbenchForDocker" 
  fi
}
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
