#!/bin/bash
source "MessageInclude.sh";
source "ArgumentsGetInclude.sh";
source "ArrayMapTestInclude.sh";
source "ComponentListVerifyInclude.sh";
source "ArgumentsDockerVerifyInclude.sh";
source "VirtCmmdInterface.sh";
source "VirtDockerInterface.sh";
source "VirtDockerReportingInterface.sh";
source "VirtDockerReportingCmmdSingleInterface.sh";
source "PacketInclude.sh";
##############################################################################
##
##  Purpose:
##    Configure reporting virtual functions to implement 'ps' command.
##
#################################################################################
##
function VirtDockerReportingCommandNameGet () {
  echo 'ps'
  return 0
}
##############################################################################
function VirtDockerReportingTargetGenerate () {
  local -r optsArgListNm="$1"
  local -r optsArgMapNm="$2"
  local -r commandNm="$3"
  local -r computePrereqs="$4"
  local -r truncGUID="$5"
  DockerTargetContainerGUIDGenerate  "$optsArgListNm" "$optsArgMapNm" "$commandNm" "$computePrereqs" "$truncGUID" 'false' 'false'
}
##############################################################################
function VirtDockerReportingJoinGUIDcolmNameGet () {
  echo 'CONTAINER ID'
  return 0
}
##############################################################################
function VirtDockerReportingHeadingRegex () {
  echo '^CONTAINER\ ID\ *IMAGE.*'
  return 0
}
##############################################################################
function VirtDockerReportingGUIDattribNameGet () {
  echo 'ContainerGUID'
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
