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
function VirtDockerReportingJoinGUIDColmPosGet () {
  echo '$1'
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
