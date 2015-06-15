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
##    Configure reporting virtual functions to implement 'images' command.
##
#################################################################################
##
function VirtDockerReportingCommandNameGet () {
  echo 'images'
  return 0
}
##############################################################################
function VirtDockerReportingTargetGenerate () {
  local -r optsArgListNm="$1"
  local -r optsArgMapNm="$2"
  local -r commandNm="$3"
  local -r computePrereqs="$4"
  local -r truncGUID="$5"
  DockerTargetImageGUIDGenerate  "$optsArgListNm" "$optsArgMapNm" "$commandNm" "$computePrereqs" "$truncGUID" 'false'
}
##############################################################################
function  VirtDockerReportingJoinGUIDcolmNameGet () {
  echo 'IMAGE ID'
  return 0
}
##############################################################################
function VirtDockerReportingHeadingRegex () {
  echo '^REPOSITORY\ *TAG\ *IMAGE\ ID.*'
  return 0
}
##############################################################################
function VirtDockerReportingGUIDattribNameGet () {
  echo 'ImageGUID'
  return 0
}
FunctionOverrideCommandGet
source "ArgumentsMainInclude.sh";
