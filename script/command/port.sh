#!/bin/bash
source "MessageInclude.sh";
source "ArgumentsGetInclude.sh";
source "ArrayMapTestInclude.sh";
source "ComponentListVerifyInclude.sh";
source "ArgumentsDockerVerifyInclude.sh";
source "VirtCmmdInterface.sh";
source "VirtDockerInterface.sh";
source "VirtDockerContainerInterface.sh";
source "VirtDockerReportingInterface.sh";
source "VirtDockerReportingCmmdMultiInterface.sh";
source "PacketInclude.sh";
##############################################################################
##
##  Purpose:
##    Configure container virtual functions to implement 'port' command.
##
#################################################################################
##
##############################################################################
function VirtDockerReportingCommandNameGet () {
  echo 'port'
}
function VirtDockerContainerCommandNameGet () {
  VirtDockerReportingCommandNameGet
}
function VirtDockerContainerOrderingGet () {
  # order of prerequsites as they are, not in reverse
  echo 'true'
}
###############################################################################
function VirtDockerCmmdExecute () {
  local -r dockerCmmd="$5"
  function VirtDockerCmmdExecuteFilter () {
    local output='NullOutput'
    local nullOutput='true'
    while read output; do
      if $nullOutput; then
        # echo a report heading
        echo 'PORT MAP'
        nullOutput='false'
      fi
      echo "$output"
    done
    if $nullOutput; then echo 'NULL_OUTPUT_GENERATED'; fi
    return 0
  }
  # run the port command, convert general error message to a reporting value
  # allow STDOUT to continue to next piped process without modification.
  eval $dockerCmmd \2\>\&\1 \>\ \>\(  \VirtDockerCmmdExecuteFilter \)
  return 0;
}
##############################################################################
function VirtDockerReportingHeadingRegex () {
  echo '^PORT\ MAP'
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
