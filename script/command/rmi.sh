#!/bin/bash
source "MessageInclude.sh";
source "ArgumentsGetInclude.sh";
source "ArrayMapTestInclude.sh";
source "ComponentListVerifyInclude.sh";
source "ArgumentsDockerVerifyInclude.sh";
source "VirtCmmdInterface.sh";
source "VirtDockerInterface.sh";
source "PacketInclude.sh";
##############################################################################
##
##  Purpose:
##    Override virtual function to set default configuration options to  
##    include those below. 
##
##  Input:
##    $0 - Name of running script that included this configuration interface.
##
##  Output:
##    When Failure: 
##      SYSERR - Reflect message indicating reason for error
##
#################################################################################
function VirtCmmdConfigSetDefault () {
  RMI_REMOVE_GUID_TARGET_LIST="$TMPDIR/$$.ImageGUIDtarget"
  REMOVE_REQ_TEMPLATE="echo local imageComponentName\=\'\$templateComponentName\'\; local imageGUIDlistFileNm\=\'\$templateGUIDfilename\'\; local imageGUID\=\'\$templateGUID\'\;"
  return 0
}
###############################################################################
##
##  Purpose:
##    Define both the options and arguments accepted by the 'images' command.
##
###############################################################################
function VirtDockerCmmdOptionsArgsDef () {
ComponentNmListArgument 'rmi' ''
ComponentVersionArgument
echo '--dlwno-order single false=EXIST=true "OptionsArgsBooleanVerify \<--dlwno-order\>" required ""'
echo '--dlwrm single false=EXIST=true "OptionsArgsBooleanVerify \<--dlwrm\>" required ""'
return 0
}

###############################################################################
##
##  Purpose:
##    Describes purpose and arguments for the 'help' command itself.
##
##  Outputs:
##    SYSOUT - The command list with descriptions.
##
###############################################################################
function VirtCmmdHelpDisplay () {
cat <<COMMAND_HELP_Purpose

Remove targeted Components' images.  Wraps Docker 'rmi' command.

Usage: dlw rmi [OPTIONS] TARGET 

COMMAND_HELP_Purpose
  HelpCommandTarget 'Careful!'
  HelpOptionHeading
  HelpComponentVersion
  echo "    --dlwrm=false         Stop and remove associated containers."
  HelpComponentOrder 'false' 'deletions'
  HelpNoExecuteDocker 'false'
  HelpShowDocker 'false'
  HelpHelpDisplay 'false'
  DockerOptionsFormat 'rmi'
}
###############################################################################
##
##  Purpose:
##    Given one or more Component names, version scope and the desired 
##    command/operation to be executed against these Component(s), map each
##    Component to a Docker Target Concept.  A Docker Target Concept can
##    either be a Repository:tag (Image Name), Image GUID, or 
##    Container GUID.
##
##    Essentially this function converts the Docker Local Workbench
##    (dlw) Component concept into is associated Docker image or container
##    objects.  A dlw Component is a analogous to class/type definition
##    that can be instantiated as an executable object.  Given this definition,
##    a Component can be directly mapped to a Docker image (class/type)
##    and a Docker container (executable object).
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
## 
##  Return Code:     
##    When Failure: 
##      Indicates unknown parse state or token type.
##
###############################################################################
function VirtDockerTargetGenerate (){
  local -r optsArgListNm="$1"
  local -r optsArgMapNm="$2"
  local -r commandNm="$3"
  # Interpert ordering option to sequence Docker rmi commands so children
  # are removed before their parents/ancestors.
  local -r orderlessRMI="`AssociativeMapAssignIndirect "$optsArgMapNm" '--dlwno-order'`"
  local -r dependGraph="`if $orderlessRMI; then echo 'false'; else echo 'reverse'; fi`"
  # Provide feature to remove orphan containers when deleting it's image,
  # as orphaned containers are essentially garbage without their base image
  # and Docker doesn't currently remove them when executing the rmi command
  local -r removeContainers="`AssociativeMapAssignIndirect "$optsArgMapNm" '--dlwrm'`"
  if $removeContainers; then
    # forward certain parameters to the rm command
    local -a rmiArgList
    local -A rmiArgMap
    if ! OptionsArgsFilter "$optsArgListNm" "$optsArgMapNm" 'rmiArgList' 'rmiArgMap' \
        '[[ "$optArg" =~ \-\-dlwcomp\-ver ]] || [[ "$optArg" =~ \-\-dlwno-exec ]] || [[ "$optArg" =~ \-\-dlwshow ]]'\
        'true'; then ScriptUnwind $LINENO "Unexpected return code."; fi
    if ! OptionsArgsFilter "$optsArgListNm" "$optsArgMapNm" 'rmiArgList' 'rmiArgMap' '[[ "$optArg" =~ Arg[0-9][0-9]* ]]' \
        'true'; then  ScriptUnwind $LINENO "Unexpected return code."; fi
    # execute the dlw rm command
    if ! eval dlw.sh rm \-f `OptionsArgsGen 'rmiArgList' 'rmiArgMap'`; then
      ScriptUnwind $LINENO "Failed to remove associated containers.";
    fi
  fi
  if ! DockerTargetImageGUIDGenerate "$1" "$2" "$3" "$dependGraph" 'false' 'true'; then ScriptUnwind $LINENO "Unexpectd return code."; fi
  return 0
}
###############################################################################
##
##  Purpose:
##    Provides a means of extending the bash variable name-value pairs 
##    defined during template resolution.
##
##    Need the image GUID targeted for delection by the Docker rmi command.
##
##  Output:   
##    When Success:
##       SYSOUT - Each record contains the desired bash varialble name
##         seperated by whitespace from the packet field name that
##         refers to the desired field value to be assigned to the 
##         bash variable name.
##    When Failure: 
##      Issues an error messages written to SYSERR, then terminate the process.
##
###############################################################################
function VirtDockerCmmdAssembleTemplateResolvePacketField () {
  echo 'PACKET_IMAGE_GUID ImageGUID'
  return 0
}
###############################################################################
##
##  Purpose:
##    Define 'docker rmi' command template.
##
###############################################################################
function VirtDockerCmmdAssembleTemplate () {
  echo '$DOCKER_CMMDLINE_OPTION  $PACKET_IMAGE_GUID'
  return 0
}
###############################################################################
function VirtDockerCmmdExecutePacketForward () {
  echo 'false'
  return 0
}
###############################################################################
##
##  Purpose:
##    Execute the image remove command, and robustly/reliantly synchronize
##    the image's removal with the appropriate Image GUID Lists maintained
##    by the Image GUID Catalog.  Docker implements three flavors of removal:
##
##    1.  An image identified by a GUID is deleted from the local repository.
##    2.  An image identified by a GUID, that's assigned a name[tag] has the
##        tag removed but not the image itself.
##    3.  When an image is deleted, it can also delete other dangling
##        ancestor images.
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
##    $4 - Variable name to an associative array containing other component 
##         specific attributes for the image targeted by the command.
##    $5 - The Docker comman to be executed.  In this case an rmi command. 
##
###############################################################################
function VirtDockerCmmdExecute () {
  local -r optsArgListNm="$1"
  local -r optsArgMapNm="$2"
  local -r commandNm="$3"
  local -r targetMapNm="$4"
  local -r dockerCmmd="$5"
  # integrate the SYSOUT & SYSERR so it can be examined 
  eval $dockerCmmd \2\>\&\1 | RMIoutputFilterPerCmmd "$optsArgListNm" "$optsArgMapNm" "$targetMapNm"

  if [ ${PIPESTATUS[1]} -ne 0 ]; then return 1; fi

  return 0;
}
###############################################################################
##
##  Purpose:
##    Scan the rmi output for possible deletions of dangling ancestor images
##    that might be managed as a statically included component in the 
##    Image GUID Catalog for the image targeted by the rmi command.  After
##    scanning the output, forward most Docker messages to either
##    SYSOUT or SYSERR. 
##
##    Also, if Docker returns an unexpected return code, individually delete
##    all image GUIDs that where successfully removed before ecountering
##    the unexpected return code.
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
##    $3 - Variable name to an associative array containing component attributes
##         for the one targeted by the rmi command.
##    SYSIN - A mixed stream of SYSOUT and SYSERR messages issued by the
##            Docker command.
## 
##  Return Code:
##    When Success:
##       RMI_REMOVE_GUID_TARGET_LIST - A temporary file that records requests
##         to remove Image GUIDs for both the targeted one(s) and its dangling
##         ancestor GUIDs that the targeted image relies on that are
##         also defined in the Image GUID Catalog.
##       SYSOUT - reflects messaged starting with "Deleted: " or 
##                "Untagged:" informational messages
##       SYSERR - reflects most messages that aren't ones that begin with
##               "Deleted:" or "Untagged:".
##
###############################################################################
function RMIoutputFilterPerCmmd () {
  local -r optsArgListNm="$1"
  local -r optsArgMapNm="$2"
  local -r targetMapNm="$3"

  local -r templateGUIDfilename="`AssociativeMapAssignIndirect "$targetMapNm" 'ImageGUIDFileName'`"
  local -r templateGUID="`AssociativeMapAssignIndirect "$targetMapNm" 'ImageGUID'`"
  local -r templateComponentName="`AssociativeMapAssignIndirect "$targetMapNm" 'ComponentName'`"
  # an associative array that consists of the current image being removed and
  # any dangling ancestors that were removed by it.  One or more of these
  # ancestors may refer to a statically linked component.
  local -A ancestorMap
  ancestorMap["$templateGUID"]="`eval $REMOVE_REQ_TEMPLATE;`"
  local calcAncestorMap='false'
  # parse the SYSOUT and SYSERR of the 'docker rmi' command
  local -r deletedLit='Deleted:'
  local -r untaggedLit='Untagged:'
  local anticipatedError='false'
  local rmiOutput
  while read rmiOutput; do 
    if [ "${rmiOutput:0:${#deletedLit}}" == "$deletedLit" ]; then
      # reflect this message to SYSOUT
      echo "$rmiOutput"
      # Identifies successfully deleted image GUID(s).  Determine if this GUID
      # is an intermediate dangling one that isn't managed by the
      # ImageGUID catalog or a statically included component or the
      # image targeted for deletion.
      local deletedGUID="${rmiOutput:${#deletedLit}+1:64}"
      local GUIDremoveRequest="${ancestorMap["$deletedGUID"]}"
      if [ -z "$GUIDremoveRequest" ]; then
        if $calcAncestorMap; then continue; fi
        # Image GUID refers to a dangling ancestor and the targeted component's
        # ancestor map hasn't been calculated yet to avoid performance 
        # penalty but need to do so now.
        calcAncestorMap='true'
        RMIancestorMapUpdate "$templateComponentName" 'ancestorMap'
        GUIDremoveRequest="${ancestorMap["$deletedGUID"]}"
        if [ -z "$GUIDremoveRequest" ]; then continue; fi
      fi
      # either the targeted image or one of its ancestors that's
      # also currently known as a prerequsite for the targeted one.
      echo "$GUIDremoveRequest">>"$RMI_REMOVE_GUID_TARGET_LIST"
      continue
    fi
    if [ "${rmiOutput:0:${#untaggedLit}}" == "$untaggedLit" ]; then
      echo "$rmiOutput"
      continue
    fi
    if [[ $rmiOutput =~ ^Error.*No.such.image:.* ]]; then
      # Image GUID was already deleted, continue with other deletes.
      # Signal delete for image GUID targeted by the rmi command.
      eval $REMOVE_REQ_TEMPLATE>>"$RMI_REMOVE_GUID_TARGET_LIST"
      # these errors can happen when an Image GUID List has stale GUIDs due to either image
      # deletions performed outside this tool or bugs in its or Docker's execution.
      anticipatedError='true'
      continue
    elif $anticipatedError; then
      anticipatedError='false'
      if [[ $rmiOutput =~ .*Error:.failed.to.remove.one.or.more.images.* ]]; then continue; fi
    fi
    # probably an error but might not be.  In any case, redirect to SYSERR
    echo "$rmiOutput">&2
    # an unexpected Docker command error, remove individual Docker Image GUIDs
    # that were successfully deleted before encountering this error.
    "ImageGUIDlist.sh" 'GUIDlistRemove' "$RMI_REMOVE_GUID_TARGET_LIST"
    rm -f "$RMI_REMOVE_GUID_TARGET_LIST"
    # resignal error
    return 1    
  done
  return 0
}
###############################################################################
##
##  Purpose:
##    Update the ancestor map to contain the provided Component's ancestor
##    image GUID(s) as keys and an image GUID removal request, encoded
##    for the ancestor, as its value.  
##
##  Assumption:
##    Since bash variable names are passed to this routine, these names
##    cannot overlap the variable names locally declared within the
##    scope of this routine or its decendents.
##
##  Inputs:
##    $1 - The child component name whose ancestor(s) may appear as 
##         dangling images.
##    $2 - Variable name to an associative array whose key is a long Image GUID
##         of child and its ancestor image GUIDs.
## 
##  Return Code:     
##    When Success:
##       $2 - May contain additional ancestor map entries to facilitate the
##            removal of dangling ancestor GUIDs that the provided component
##            relies on and are also defined in the Image GUID Catalog.
##
###############################################################################
function RMIancestorMapUpdate () {
  local -r componentName="$1"
  local -r ancestorMapNm="$2"

  local -a rmiOptsArgList
  local -A rmiOptsArgMap
  local -r compMapNm='rmi'
  # obtain all ancestors for gven component.
  rmiOptsArgList[0]='--dlwno-order'
  rmiOptsArgMap['--dlwdepnd']='false'
  # obtain every component version for a given component
  rmiOptsArgList[1]='--dlwcomp-ver'
  rmiOptsArgMap['--dlwcomp-ver']='all'
  # supply the target component name
  rmiOptsArgList[2]='Arg1'
  rmiOptsArgMap['Arg1']="$componentName"
  # verify the RMI arguments to ensure proprer execution of DockerTargetImageGUIDGenerate below.
  if ! VirtCmmdOptionsArgsVerify 'rmiOptsArgList' 'rmiOptsArgMap'; then ScriptUnwind  $LINENO "Ancestor command options/arguments invalid."; fi
  # filter the return Image GUIDs limiting them to only ancestor images.
  local -A componentMap
  local ancestorPacket
  while read ancestorPacket; do
    PipeScriptNotifyAbort "$ancestorPacket"
    if ! PacketPreambleMatch "$ancestorPacket"; then     
      echo "$ancestorPacket"
      continue
    fi
    # unpack ancestor packet to get necessary data
    unset componentMap
    local -A componentMap
    PacketConvertToAssociativeMap "$ancestorPacket" 'componentMap'
    local ancestorName="`AssociativeMapAssignIndirect 'componentMap' 'ComponentName'`"
    # consider packets that are only ancestors as defined by the dependency graph.
    # not the actual child
    if [ "$ancestorName" == "$componentName" ]; then continue; fi
    # it's an ancestor. Add it to the ancestor associated array with its
    # removal request.
    local templateGUIDfilename="`AssociativeMapAssignIndirect 'componentMap' 'ImageGUIDFileName'`"
    local templateGUID="`AssociativeMapAssignIndirect 'componentMap' 'ImageGUID'`"
    local templateComponentName="$ancestorName"
    eval $ancestorMapNm\[\"\$templateGUID\"]=\"\`$REMOVE_REQ_TEMPLATE\`\"
  done < <( DockerTargetImageGUIDGenerate 'rmiOptsArgList' 'rmiOptsArgMap' 'rmi' 'reverse' 'false' 'false' )
  return 0
}
###############################################################################
##
##  Purpose:
##    After removing images from the local Docker repository, now remove
##    references to these destroyed images from the Image GUID List(s).
##    Optimize the removal process by converting individual GUID removal
##    requests, based on a GUID into those based on a component version
##    when possible.
##
##  Notes:
##    It's not possible to optimize dangling ancestor removal requests.
##    There shouldn't be dangling ancestors for Components being managed when
##    targeting 'all' Components.
##    Updates to the Image GUID lists do not have to be ordered according
##    to their dependencies.
##    This routine is only called if there isn't a failure.  During failres
##    the individual deletes are applied, without optimization by another
##    function.
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
##    RMI_REMOVE_GUID_TARGET_LIST - A temporary file containing all the Image
##         GUID List file names and GUIDs successfully removed from the local
##         Docker repository.
## 
##
###############################################################################
function VirtDockerCmmdExecuteAtCompletion () {
  local -r optsArgListNm="$1"
  local -r optsArgMapNm="$2"
  local -r commandNm="$3"
  if [ ! -f "$RMI_REMOVE_GUID_TARGET_LIST" ]; then return 0; fi
  local -r componentVerRemoved="`AssociativeMapAssignIndirect "$optsArgMapNm" '--dlwcomp-ver'`"
  local -A compTargetMap
  CompNameMapGen "$optsArgListNm" "$optsArgMapNm" 'compTargetMap'
  local -r RMI_REMOVE_ANCESTOR_GUID_LIST="`mktemp --tmpdir="$TMPDIR"`"
  local currentComponentName
  local danglingAncestor='false'
  local entry
  while read entry; do
    eval $entry
    if [ "$imageComponentName" != "$currentComponentName" ]; then
      currentComponentName="$imageComponentName"
      if [ "${compTargetMap["$currentComponentName"]}" == 'true' ] || [ "${compTargetMap['all']}" == 'true' ]; then 
        # a component directly targeted as an argument by rmi command.
        # remove it according to its version specifier - might be more
        # efficient than individual deletes.
        if ! "ImageGUIDlist.sh" "${componentVerRemoved}Remove" "$imageGUIDlistFileNm"; then return 1; fi
        danglingAncestor='false'
        continue
      else
        danglingAncestor='true'
      fi
    fi
    if $danglingAncestor; then 
      # buffer dangling ancestor GUID removal requests for later deletion. 
      echo "$entry">>"$RMI_REMOVE_ANCESTOR_GUID_LIST"
    fi
  done < <( sort < "$RMI_REMOVE_GUID_TARGET_LIST" )
  if [ -f "$RMI_REMOVE_ANCESTOR_GUID_LIST" ]; then
    # process all buffered dangling ancestor requests
    if ! "ImageGUIDlist.sh" 'GUIDlistRemove' "$RMI_REMOVE_ANCESTOR_GUID_LIST"; then
      ScriptUnwind  $LINENO "Problem while removing dangling ancestor for component: '$currentComponentName', Ancestor list: '$RMI_REMOVE_ANCESTOR_GUID_LIST'."
      rm -f "$RMI_REMOVE_ANCESTOR_GUID_LIST">/dev/null
    fi
  fi
  rm -f "$RMI_REMOVE_GUID_TARGET_LIST"
  return 0
}
###############################################################################
##
##  Purpose:
##    Implements the dlw build command. dlw build command is a wrapper that
##    calls the Docker build command.  dlw assembles command line options
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
##    $3 - dlw command to execute. Maps 1 to 1 onto with Docker command line.
##    
##  Outputs:
##    When Successful:
##      SYSOUT - Indicates build operation completed successfully.
##    When Failure: 
##      SYSERR - Displays informative error message.
##
###############################################################################
function VirtCmmdExecute (){
  VirtDockerMain "$1" "$2" 'rmi'
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
