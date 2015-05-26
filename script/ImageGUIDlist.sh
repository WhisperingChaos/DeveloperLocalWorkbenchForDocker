#!/bin/bash
###############################################################################
##
##  Purpose:
##    Implement a layer of routines to manage/centralize the semantics of methods
##    that affect Image GUID Lists of the Image GUID Catalog.
##  
##  Notes: Methods Adding GUIDs:  
##    1.  Methods responsible for Added GUIDs should always update an Image
##        GUID List mtime, even in situations where the content hasn't changed.
##
##  Notes: Methods Removing GUIDs:  
##    1. When removing GUIDs from an Image GUID List, preserve the file's (List's)
##       modification date/time stamp: mtime, as only adding GUIDs should change
##       this date.  Retaining mtime allows a user to flexibility perform
##       image removals and update image resources for any image in any order 
##       while preserving a user's expectation that changes to image resources
##       will trigger a build.
##
###############################################################################
##
##
###############################################################################
##
##  Purpose:
##    Add/Or update an Image GUID List to contain the Docker image GUID
##    of the newly constructed image.  The GUID for the most current Image
##    verision is always the last GUID in the file.
##
##  Input:
##    $1 - File path name to the Image GUID List.
##    $2 - Docker image name.
##    $3 - Optional Component description.
##
###############################################################################
function Add () {
  if [ "$1" == "" ]; then Unwind $LINENO "Missing file path to Image GUID List."; fi 
  if [ "$2" == "" ]; then Unwind $LINENO "Missing Docker image name."; fi
  local -r componentDesc="$3"
  local dockerImageKey  
  if ! dockerImageKey=`docker inspect --format="{{.Id}}" $2`; then Unwind $LINENO; fi
  # create Image GUID Catalog if it doesn't already exist
  local -r imageGUIDcat="`dirname "$1"`"
  if ! [ -d "$imageGUIDcat" ]; then
    if ! mkdir -p "$imageGUIDcat" >/dev/null; then Unwind $LINENO; fi
  fi
  # create Image Time Stamp Catalog if it doesn't already exist
  if ! [ -d "$IMAGE_BUILD_TIMESTAMP_DIR" ]; then
    if ! mkdir -p "$IMAGE_BUILD_TIMESTAMP_DIR" >/dev/null; then Unwind $LINENO; fi
  fi
  # Add/build operation  - always update image's time stamp
  local buildTmStmpFileName
  BuildTimeStampNameGen "$1" 'buildTmStmpFileName'
  if ! touch "$buildTmStmpFileName"; then Unwind $LINENO "Problem touching file: '$buildTmStmpFileName'."; fi
  while true; do
    # determine if Image GUID List needs to be updated
    if ! [ -e "$1" ]; then break; fi
    if ! [ -s "$1" ]; then break; fi
    local currentImageGUID
    if ! currentImageGUID="`Current "$1" | awk '{ print $1 }'`"; then Unwind $LINENO; fi
    if [ "$currentImageGUID" == "$dockerImageKey" ]; then
       # nothing really changed since last build :: don't 
       # update the Image GUID List file
       return 0;
    fi
    #  image GUID is different :: the build actually changed the contents of the
    #  image, so save this new GUID.
    break;
  done
  if ! echo "$dockerImageKey componentPropBag='([ComponentDescription]=\"$componentDesc\")'" >> "$1"; then Unwind $LINENO; fi
  return 0;
}
###############################################################################
##
##  Purpose:
##    Stream only the last Image ID from the provided file.  The last image
##    id is considered the most recent one.
##
##  Inputs:
##    $1 - File path name to Image GUID List.  
##
###############################################################################
function Current () {
  tail -1 <"$1"
}
###############################################################################
##
##  Purpose:
##    Remove only the current image version as known to the build system.
##    After removing the current Image GUID from a given Image GUID List,
##    determine if the List is empty.  If it is, delete it.
##  
##  Notes:  
##    1. See above: Notes: Methods Removing GUIDs: 
##
##  Inputs:
##    $1 - File path name to Image GUID List.  
## 
###############################################################################
function CurrentRemove () {
  if ! [ -f "$1" ]; then return 0; fi
  local FileNmPthTmp
  if ! FileNmPthTmp="`mktemp --tmpdir="$TMPDIR"`"; then Unwind $LINENO; fi
  if ! head --lines=-1 < "$1" > "$FileNmPthTmp"; then Unwind $LINENO; fi
  local CurrentContent
  if ! CurrentContent=`Current "$FileNmPthTmp"`; then Unwind $LINENO; fi
  if [ "$CurrentContent" == "" ]; then                              
    if ! AllRemove "$1";          then Unwind $LINENO; fi
    if ! rm "$FileNmPthTmp";      then Unwind $LINENO; fi
  elif ! mv "$FileNmPthTmp" "$1"; then Unwind $LINENO; fi
  return 0;
}
###############################################################################
##
##  Purpose:
##    Stream every image GUID from the provided file in reverse order: from 
##    the bottom, most recent, to the top, least recent (oldest).
##
##  Inputs:
##    $1 - File path name to Image GUID List.
## 
###############################################################################
function All () {
  tac "$1";
}
###############################################################################
##
##  Purpose:
##    Delete the Image GUID List.  Presumeably all images in the file have been
##    removed from the local repository.
##
##  Inputs:
##    $1 - File path name to Image ID catalog file.  
## 
###############################################################################
function AllRemove () {
  if ! [ -f "$1" ]; then return 0; fi
  if ! rm "$1";     then Unwind $LINENO; fi
  if ! BuildTimeStampRemove "$1"; then Unwind $LINENO; fi
}
###############################################################################
##
##  Purpose:
##    Stream every image GUID from the provided file in reverse order: from 
##    the bottom, most recent, to the top, least recent (oldest) except for
##    the most current image GUID
##
##  Inputs:
##    $1 - File path name to Image GUID List.
## 
###############################################################################
function AllExceptCurrent () {
  All "$1" | awk '{if(NR>1)print}'
}
###############################################################################
##
##  Purpose:
##    Remove all GUIDs from the Image GUID List, execpt for the current one.
##
##  Inputs:
##    $1 - File path name to Image GUID List.
## 
###############################################################################
function AllExceptCurrentRemove () {
  if ! [ -f "$1" ]; then return 0; fi
  local CurrentGUID
  if ! CurrentGUID=`Current "$1"`; then Unwind $LINENO; fi
  if ! echo "$CurrentGUID">"$1";   then Unwind $LINENO; fi
  return 0
}
###############################################################################
##
##  Purpose:
##    Provide a method to remove individual GUIDs from one or more Image GUID
##    Lists.  Generally executed when one of the more aggregate methods above
##    partially succeeds: removes at least one or more Images from the local
##    dokcer repository, but not all of them.
##
##  Inputs:
##    $1 - File path name to a list consisting of a list of bash environment
##         variable assignments.  Each row of the list defines two assignment
##         statements.  The first being the Image GUID List file name, and 
##         the second being the actual image GUID in its long form.  The bash
##         variable name representing the Image GUID List file name must
##         be: 'imageGUIDlistFileNm', while the image GUID variable name
##         must be: 'imageGUID'
##
##         The positioning of these assignments in each row is important because
##         a blind sort is performed to group all rows targeting a particular
##         Image GUID List in order to optimize the IO and other effort
##         required to remove GUIDS from a specific Image GUID List.
## 
##         Example row: 'local imageGUIDlistFileNm='./image/sshserver.build' local imageGUID='1ad4eca92f52d956b100960fa650933d3976bfeb7b6573419bfbc789f572f112'
## 
###############################################################################
function GUIDlistRemove () {
  local -r GUIDlistFileName="$1"
  if ! [ -f "$GUIDlistFileName" ]; then return 0; fi 
  local GUIDlistImageFileCurrent
  local -A GUIDlistMap
  local row
  while read row; do
    eval $row
    if [ "$GUIDlistImageFileCurrent" != "$imageGUIDlistFileNm" ]; then
      if [ -n "$GUIDlistImageFileCurrent" ]; then
        if ! GUIDlistRemoveScan "$GUIDlistImageFileCurrent" 'GUIDlistMap'; then Unwind $LINENO; fi
      fi
      GUIDlistImageFileCurrent="$imageGUIDlistFileNm"
      unset GUIDlistMap
      local -A GUIDlistMap
    fi
    GUIDlistMap["$imageGUID"]='true'
  done < <( sort < "$GUIDlistFileName" )
  # trailing scan trigger - executes last scan for the last non empty map
  if [ "${#GUIDlistMap[@]}" -ne '0' ]; then
    if ! GUIDlistRemoveScan "$GUIDlistImageFileCurrent" 'GUIDlistMap'; then Unwind $LINENO; fi
  fi
  return 0
}
###############################################################################
##
##  Purpose:
##    Given a list of GUIDs you wish to remove, perform a join with
##    the GUIDs in the image file list and remove the matching ones.
##
##  Assumptions:
##    The routine below is written to preserve the ording of the GUIDs
##    in the Image GUID List file.
##
##  Inputs:
##    $1 - File path name to the Image GUID List from which to remove the
##         GUIDs provided by the second argument.
##    $2 - Bash variable name of an associative map, such that, its key is 
##         a long GUID and its value is 'true'.  Each entry in the map
##         identifies an individual GUID that must be removed.
##
##  Outputs:
##    When Successful:
##      An Image GUID List, preserving the ordering of the original, without
##      the GUIDS specified by the associative map.  If all the GUIDs have
##      been removed, then the Image GUID List is removed.
## 
###############################################################################
function GUIDlistRemoveScan () {
  local -r imageGUIDListFileName="$1"
  local -r imageGUIDMapNm="$2"
  local atLeastOne='false'
  if ! local -r GUIDlistRemainFileNm="`mktemp --tmpdir="$TMPDIR"`"; then Unwind $LINENO; fi
  local entry
  while read entry; do
    local imageGUID="${entry:0:64}"
    eval local removeGUID=\"\$\{$imageGUIDMapNm\[\"\$imageGUID\"]\}\"
    if [ "$removeGUID" == 'true' ]; then continue; fi
    atLeastOne='true'
    echo "$entry">>"$GUIDlistRemainFileNm"
  done < "$imageGUIDListFileName"
  if $atLeastOne; then
    if ! mv "$GUIDlistRemainFileNm" "$imageGUIDListFileName"; then Unwind $LINENO; fi
  else
   if ! rm "$imageGUIDListFileName";                   then Unwind $LINENO; fi
   if ! BuildTimeStampRemove "$imageGUIDListFileName"; then Unwind $LINENO; fi
   if ! rm "$GUIDlistRemainFileNm";                    then Unwind $LINENO; fi
  fi
  return 0
}
###############################################################################
##
##  Purpose:
##    Remove the build timestamp file used as a surrogate to represent 
##    the docker image produced by a Compoent's resources.
##
##  Input:
##    $1 - Image GUID List file location.
##
###############################################################################
function BuildTimeStampRemove () {
  local buildTmStmpFileName
  BuildTimeStampNameGen "$1" 'buildTmStmpFileName'
  if ! rm "$buildTmStmpFileName"; then Unwind $LINENO; fi
}

function BuildTimeStampNameGen () {
  local buildTimeStampFileNameIt="$IMAGE_BUILD_TIMESTAMP_DIR/`basename "$1" .GUIDlist`.build"
  if ! eval $2=\"\$buildTimeStampFileNameIt\"; then Unwind $LINENO; fi
}
###############################################################################
##
##  Purpose:
##    Terminates the execution of the script while providing minimal
##    debugging information that includes the script line
##    number of the offending command.  Note what's reported is not a complete
##    call stack 
##
##  Input:
##    $1 - LINENO of calling location: 
##    $2 - Optional message text.
##
###############################################################################
function Unwind (){
  local messageText
  messageText="Unwinding script stack."
  if [ "$2" != "" ]; then messageText="$2"; fi
  echo "Abort: Module: '$0', LINENO: '$1', $messageText" >&2
  exit 1
}
###############################################################################
##
##  Purpose:
##    Encapsulates the methods that operate on an Image GUID List.
##    An Image GUID List is implemented as a file containing 1 to n
##    Docker long image GUIDs.  These GUIDs represent different image versions
##    of a single Component.  A Component defines a single Docker build context:
##    its Dockerfile and referenced resources.  Different image versions
##    arise through changes applied to the Component's build context.  The Image
##    GUID List is ordered from least recent (oldest) to the most current Component
##    version, with the most current image GUID located at the file's bottom.
##    
##  Inputs:
##    $1    - Method name.
##    $2-$N - Method argument list. 
## 
###############################################################################
  case "$1" in
    Add)	            Add                    "$2" "$3" "$4" ;; 
    Current)                Current                "$2"           ;;
    cur)                    Current                "$2"           ;;
    curRemove)              CurrentRemove          "$2"           ;;
    All)                    All                    "$2"           ;;
    all)                    All                    "$2"           ;;
    allRemove)              AllRemove              "$2"           ;;
    AllExceptCurrent)       AllExceptCurrent       "$2"           ;;
    allButCur)              AllExceptCurrent       "$2"           ;;
    allButCurRemove)        AllExceptCurrentRemove "$2"           ;;
    GUIDlistRemove)         GUIDlistRemove         "$2"           ;;
    *) Unwind $LINENO "Unknown method specified: '$1'"            ;;
  esac
  if [ $? -ne 0 ]; then Unwind $LINENO; fi
exit 0;
###############################################################################
# 
# The MIT License (MIT)
# Copyright (c) 2014 Richard Moyse License@Moyse.US
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
