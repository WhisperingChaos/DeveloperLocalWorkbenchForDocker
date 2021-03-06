#!/bin/bash
###############################################################################
##
##    Section: Abstract Interface:
##      Declate abstract interface for reporting commands like 'history' &
##     'top' that require aggregating output from one or more individual
##     commands to produce a consolidated report.
##
###############################################################################
##
###############################################################################
##
##  Purpose:
##    Identifies dlw attribute name of the desired GUID.  Essentially, two
##    types: 'ImageGUID' and a 'ContainerGUID'.
##
##  Inputs:
##    None
##    
##  Outputs:
##    When Successful:
##      SYSOUT - Name of dlw attrubute name.
##    When Failure: 
##      SYSERR - Displays informative error message.
##
###############################################################################
function VirtDockerReportingGUIDattribNameGet () {
  ScriptUnwind $LINENO "Please override: $FUNCNAME".
}
###############################################################################
##
##  Purpose:
##    Define common options and arguments accepted by reports
##    generated by aggregating multiple Docker container commands.
##
###############################################################################
function VirtDockerCmmdOptionsArgsDef () {
  local -r commandName="`VirtDockerReportingCommandNameGet`"
  ComponentNmListArgument "$commandName" 'all'
  ComponentVersionArgument 'cur'
  ColumnHeadingRemove
  echo '--dlwcol single "ComponentName/COMPONENT/15,ContainerGUID/CONTAINER ID/12,=EXIST=none" "ColumnSelectExcludeVerify \<--dlwcol\>" required ""'
  echo '--dlwno-prereq single order=EXIST=true "ComponentNoPrereqVerify \<--dlwno-prereq\>" required ""'
  echo '--dlwign-state single false=EXIST=true "OptionsArgsBooleanVerify \<--dlwign-state\>" required ""'
return 0
}
###############################################################################
##
##  Purpose:
##    Describes purpose and arguments common options and arguments
##    accepted by reports generated by aggregating multiple Docker
##    container commands.
##
###############################################################################
function VirtCmmdHelpDisplay () {
local -r commandName="`VirtDockerReportingCommandNameGet`"
ComponentNmListArgument "$commandName" 'all'

cat <<COMMAND_HELP_Purpose

Report on targeted Components' container(s) ports.  Wraps Docker '$commandName' command.

Usage: dlw $commandName [OPTIONS] TARGET 

COMMAND_HELP_Purpose
  HelpCommandTarget
  HelpOptionHeading
  HelpComponentVersion 'cur'
  HelpComponentNoPrereq "$commandName" 'order'
  HelpIgnoreStateDocker 'false'
  HelpNoExecuteDocker 'false'
  HelpShowDocker 'false'
  HelpColumnSelectExclude 'ComponentName/COMPONENT/15,ContainerGUID/CONTAINER ID/12'
  HelpColumnHeadingRemove 'false'
  HelpHelpDisplay 'false'
  DockerOptionsFormat "$commandName"
}

function VirtContainerStateFilterApply () {
  local -r dockerStatus="$1"
  if [ "${dockerStatus:0:2}" == 'Up' ]; then
    return 0;
  fi
  return 1
}

function VirtDockerCmmdExecutePacketForward () {
  echo 'true'
}
###############################################################################
##
##  Purpose:
##    Capture Docker reporting command output generated by multiple Docker
##    commands and aggregrate it into a consolidated report.
##
##  Assumption:
##    Since bash variable names are passed to this routine, these names
##    cannot overlap the variable names locally declared within the
##    scope of this routine or its decendents.
##
##  Inputs:
##    $1 - Variable name to an array whose values contain the label names
##         of the options and agruments appearing on the command line in the
##         order specified by it.
##    $2 - Variable name to an associative array whose key is either the
##         option or argument label and whose value represents the value
##         associated to that label.
##    $3 - dlw command to execute. Maps 1 to 1 onto with Docker command line.
##    SYSIN - Output from the Execute command.
## 
##  Inputs:
##    SYSOUT - A filtered Docker report displaying only the specified Components.
##             The report may also be augmented with additional column(s)
## 
###############################################################################
function VirtDockerCmmdProcessOutput () {
  local -r optsArgListNm="$1"
  local -r optsArgMapNm="$2"
  local -r commandNm="$3"
  local outputHeadingNot
  AssociativeMapAssignIndirect "$optsArgMapNm" '--dlwno-hdr' 'outputHeadingNot'
  local -A colmIncludeMap
  if ! ColmIncludeDetermine "`AssociativeMapAssignIndirect "$optsArgMapNm" '--dlwcol'`" 'colmIncludeMap'; then
    ScriptUnwind $LINENO "Problem with --dlwcol argument."
  fi
  if [ -n "${colmIncludeMap['none']}" ]; then
    # specifying 'none' as an attribute name omits all extended columns.
    unset colmIncludeMap
    local -A colmIncludeMap
  fi
  local GUIDvalue
  local GUIDattribName="`VirtDockerReportingGUIDattribNameGet`"
  local headingProcessed='false'
  local headingRemoved='false'
  local packetContainerMapPrior='false'
  local serializedColmBagArray
  local packet
  while read packet; do
    PipeScriptNotifyAbort "$packet"
    if PacketPreambleMatch "$packet"; then
      if $packetContainerMapPrior; then
        # Two container packets in a row, missing output for prior. Generate message
        echo "Missing output for: '$GUIDvalue' "
      fi
      packetContainerMapPrior='true'
      local -A GUIDvalueMap
      unset GUIDvalueMap
      local -A GUIDvalueMap
      PacketConvertToAssociativeMap "$packet" 'GUIDvalueMap'
      local GUIDvalue="${GUIDvalueMap["$GUIDattribName"]}"
      if [ -z "$GUIDvalue" ]; then echo "$packet"; fi # packet detected but not of desired type - forward it.
      # determine the columns to display for this entry and compute the complete
      # set of extended columns supported  by the report after visiting all packets.
      local -a colmBagArray
      unset colmBagArray
      local -a colmBagArray
      if ! ColumnAttributesDiscern 'colmIncludeMap' 'GUIDvalueMap' 'colmBagArray'; then 
        ScriptUnwind $LINENO "Problem while discerning report column attributes."
      fi
      local serializedColmBagArray="`typeset -p colmBagArray`"
      # State has been established for fields below
      # Potential heading exists before continue processing packets until first non-packet
      headingRemoved='false'
      continue
    fi
    # A completely empty report line.  Nothing to report on :: read next line.
    # Conforms to usual Docker daemon behavior to only generate Docker header
    # without detail lines if there isn't reporting detail to display.
    if [ "$packet" == 'NULL_OUTPUT_GENERATED' ]; then
      packetContainerMapPrior='false'
      continue
    fi
    if ! $headingProcessed; then
      # first non-packet is output from Docker reporting command.  Most likely a heading
      # if not omitted by, for example, the -q option.
      headingProcessed='true'
      local dockerHdrInd='false'
      if DockerHeadingSpecified "$packet"; then dockerHdrInd='true'; fi 
      if ! $outputHeadingNot; then
        #  user wants dlw column headings, but are there Docker headings
        if $dockerHdrInd; then
          if [ "${#colmIncludeMap[@]}" -gt 0 ]; then
            # packet contained Docker report heading :: prefix with extended attributes column headings.
            echo "`ExtendedHeadingsGenerate 'colmIncludeMap'` $packet"
          else
            # no extended columns in this report :: output Docker heading
            echo "$packet"
          fi
          continue
        elif [ "${#colmIncludeMap[@]}" -gt 0 ]; then
          # dlw heading requested, but most likely Docker report heading omitted.
          # packet probably contains detail row of report so let it be considered
          # below, however, generate dlw column headings.
          echo "`ExtendedHeadingsGenerate 'colmIncludeMap'`"
        fi
        # Docker heading detected but headings are suppressed 
        headingRemoved='true'
      fi
    fi
    if ! $headingRemoved; then
      headingRemoved='true'
      if DockerHeadingSpecified "$packet"; then
        continue
      fi
    fi
    # not a heading nor a dlw packet, most likely a reporting detail row.
    # extend report with requested columns.
    packetContainerMapPrior='false'
    if [ "${#colmIncludeMap[@]}" -gt 0 ] && [ -n "$serializedColmBagArray" ] ; then
      # extended columns are requested for the report
      local colmExendedBuf
      ExtendedColumnsGenerate 'colmIncludeMap' "$serializedColmBagArray" 'colmExendedBuf' 
      echo "${colmExendedBuf} ${packet}"
    else
      echo "${packet}"
    fi
  done
  return 0
}
##############################################################################
function VirtDockerReportingGUIDattribNameGet () {
  echo 'ContainerGUID'
  return 0
}
FunctionOverrideIncludeGet
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
