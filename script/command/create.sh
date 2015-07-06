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

Create container for targeted component(s).  Wraps Docker 'create' command.

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
