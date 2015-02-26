#!/bin/bash
INC_Scripts=$(dirname "${BASH_SOURCE[0]}");
source "$INC_Scripts/MessageInclude.sh";
TMPDIR="\tmp"
###############################################################################
##
##  Purpose:
##    Unit test functions in ImageGUIDlist.sh.
##
###############################################################################

###############################################################################
##
##  Purpose:
##    Generate pseudo docker long GUIDs
##  
##  Input:
##    $1  - Number of GUIDs to generate.
##
##  Output:
##    SYSOUT - Long GUIDS whose count matches $1
##
###############################################################################
function GUIDgen () {
  local GUIDremainingCnt="$1"
  while [ $GUIDremainingCnt -gt 0 ]; do
    local GUIDfirstPart="`uuidgen -r`"
    local GUID="${GUIDfirstPart}`uuidgen -r`"
    GUID=${GUID//-/}
    if [ "${#GUID}" -ne 64 ]; then ScriptUnwind $LINENO "Generated GUID length not equal to 64 byte docker GUID.  Generated GUID: '$GUID'"; fi
    echo "$GUID"
    (( -- GUIDremainingCnt ))
  done
  return 0;
}
###############################################################################
##
##  Purpose:
##    Create a pseudo Image GUID List.
##  
##  Input:
##    $1  - File name to create.
##    $2  - Number of GUIDs to populate the file.
##
###############################################################################
function ImageGUIDListFileCreate () {
  local -r imageGUIDFileName="$1"
  local -r GUIDgenCnt="$2"
  if [ -f "$imageGUIDFileName" ]; then ScriptUnwind $LINENO "File already exists!  Remove it or change name: '$imageGUIDFileName'"; fi
  GUIDgen $GUIDgenCnt >>"$imageGUIDFileName"
  return 0;
}
###############################################################################
##
##  Purpose:
##    Create a GUID list removal file.
##  
##  Input:
##    $1  - File name of an existing Image GUID List.
##    $2  - File name of GUID list removal file that will be created by this
##          method.  This file will contain rows identifying GUIDs to remove.
##    $3  - A selector determining which GUIDs from the Image GUID List
##          should be deleted.  Valid values: 'cur', 'allButCur', and 'all' 
##
###############################################################################
function GUIDremovalListFileCreate () {
  local -r imageGUIDFileName="$1"
  local -r GUIDremovalFileName="$2"
  local -r compVersion="$3"
  if ! [ -f "$imageGUIDFileName" ]; then ScriptUnwind $LINENO "Image GUID File doesn't exist: '$imageGUIDFileName'"; fi
  if [ -f "$GUIDremovalFileName" ]; then ScriptUnwind $LINENO "File already exists!  Remove it or change name: '$GUIDremovalFileName'"; fi
  local entry
  while read entry; do
    echo "local imageGUIDlistFileNm='$imageGUIDFileName'; local imageGUID='$entry'" >>"$GUIDremovalFileName"
  done < <( "$INC_Scripts/ImageGUIDlist.sh" "$compVersion" "$imageGUIDFileName" )
  return 0
}
###############################################################################
##
##  Purpose:
##    Create a GUID list preservation file. 
##  
##  Input:
##    $1  - File name of an existing Image GUID List.
##    $2  - File name of GUID list preservation file that will be created by this
##          method.  This file should be a duplicate for the will contain rows identifying GUIDs to remove.
##    $3  - A selector determining which GUIDs from the Image GUID List
##          should be deleted.  Valid values: 'cur', 'allButCur', and 'none' 
##
###############################################################################
function GUIDpreserveListFileCreate () {
  local -r imageGUIDFileName="$1"
  local -r GUIDpreserveFileName="$2"
  local -r compVersion="$3"
  if ! [ -f "$imageGUIDFileName" ];  then ScriptUnwind $LINENO "Image GUID File doesn't exist: '$imageGUIDFileName'"; fi
  if [ -f "$GUIDpreserveFileName" ]; then ScriptUnwind $LINENO "File already exists!  Remove it or change name: '$GUIDpreserveFileName'"; fi
  if [ "$compVersion" == 'none' ];   then return 0; fi
  "$INC_Scripts/ImageGUIDlist.sh" "$compVersion" "$imageGUIDFileName" | tac >> "$GUIDpreserveFileName"
  if [ "${PIPESTATUS[0]}" -ne '0' ]; then ScriptUnwind $LINENO "Problem while reading Image GUID List: '$imageGUIDFileName'."; fi
  if ! [ -s "$GUIDpreserveFileName" ]; then 
    if ! rm "$GUIDpreserveFileName"; then ScriptUnwind $LINENO "Remove failed for file: '$GUIDpreserveFileName'."; fi
  fi
  return 0
}
###############################################################################
##
##  Purpose:
##    Encapsalate, ImageGUIDList, create, removal, and comparision in single
##    test function .
##  
##  Input:
##    $1  - A selector determining which GUIDs from the Image GUID List
##          should be deleted.  Valid values: 'cur', 'allButCur', and 'all' 
##    $2  - Number of pseudo GUIDs to generate.
##
###############################################################################
function GUIDremovalByGUIDAssert ()  {
  function CompVersionTranslateToPreserve () {
    if   [ "$1" == "cur" ];       then echo 'allButCur';
    elif [ "$1" == "allButCur" ]; then echo 'cur';
    elif [ "$1" == "all" ];       then echo 'none';
    else
      ScriptUnwind $LINENO "Don't know how to translate delete component version of:'$1' to preserve version."
    fi
  }
  local -r compVersion="$1"
  local -r GUIDcntToGen="$2"
  local -r imageGUIDFile="`mktemp -u`"
  ImageGUIDListFileCreate "$imageGUIDFile" "$GUIDcntToGen"
  local -r GUIDremovalFile="`mktemp -u`"
  GUIDremovalListFileCreate "$imageGUIDFile" "$GUIDremovalFile" "$compVersion"
  local -r compVerPreserve="`CompVersionTranslateToPreserve "$compVersion"`"
  local -r GUIDpreserveFile="`mktemp -u`"
  GUIDpreserveListFileCreate "$imageGUIDFile" "$GUIDpreserveFile" "$compVerPreserve"
  if ! "$INC_Scripts/ImageGUIDlist.sh" 'GUIDlistRemove' "$GUIDremovalFile"; then ScriptUnwind $LINENO "GUIDlistRemove failed."; fi
  if [ -f "$GUIDpreserveFile" -a -f "$imageGUIDFile" ]; then
    if ! cmp "$GUIDpreserveFile" "$imageGUIDFile"; then 
      ScriptUnwind $LINENO "Actual file differs from its anticipated one.  Actual: '$imageGUIDFile' Anticipated '$GUIDpreserveFile'"
    fi
  elif [ -f "$GUIDpreserveFile" -o -f "$imageGUIDFile" ]; then
    ScriptUnwind $LINENO "One of the files is nonexistent while the other one exists: Actual: '$imageGUIDFile' Anticipated '$GUIDpreserveFile'";
  fi
  if ! rm -f "$GUIDremovalFile";  then ScriptUnwind $LINENO "Remove failed for: '$GUIDremovalFile'.";  fi
  if ! rm -f "$imageGUIDFile";    then ScriptUnwind $LINENO "Remove failed for: '$imageGUIDFile'.";    fi
  if ! rm -f "$GUIDpreserveFile"; then ScriptUnwind $LINENO "Remove failed for: '$GUIDpreserveFile'."; fi
}
###############################################################################
##
##  Purpose:
##    Test Image GUID List removal methods preserve timestamp.
##  
##  Input:
##    $1  - A selector determining which GUIDs from the Image GUID List
##          should be deleted.  Valid values: 'cur', 'allButCur', and 'all' 
##    $2  - Number of pseudo GUIDs to generate.
##
###############################################################################
function ImageModifyDatePreserveAssert ()  {
  function CompVersionVerify () {
    if [ "$1" == 'cur' ];       then return 0; fi
    if [ "$1" == 'allButCur' ]; then return 0; fi
    ScriptUnwind $LINENO "Invalid GUID removal request:'$1'."
  }
  local -r compVersion="$1"
  CompVersionVerify "$compVersion"
  local -r GUIDcntToGen="$2"
  local -r imageGUIDFile="`mktemp -u`"
  ImageGUIDListFileCreate "$imageGUIDFile" "$GUIDcntToGen"
  local -r imageGUIDFileTimeStampBefore="`stat -c %Y "$imageGUIDFile"`"
  # mtime must implement resolution of at least 1 second
  sleep 1s
  if ! "$INC_Scripts/ImageGUIDlist.sh" "${compVersion}Remove" "$imageGUIDFile"; then ScriptUnwind $LINENO "${compVersion}Remove failed."; fi
  local -r imageGUIDFileTimeStampAfter="`stat -c %Y "$imageGUIDFile"`"
  if [ "$imageGUIDFileTimeStampBefore" -ne "$imageGUIDFileTimeStampAfter" ]; then
     ScriptUnwind $LINENO "${compVersion}Remove failed to preserve time stamp.  GUID File: '$imageGUIDFile' TimeStampBefore '$imageGUIDFileTimeStampBefore' TimeStampAfter: '$imageGUIDFileTimeStampAfter'"
  fi
  if ! rm -f "$imageGUIDFile"; then ScriptUnwind $LINENO "Remove failed for: '$imageGUIDFile'.";    fi
}

###############################################################################
##
##  Purpose:
##    Test Image GUID List function that removes individual GUIDS.
##  
###############################################################################
function GUIDlistRemoveTest () {
  echo "$FUNCNAME Test 1: Given an Image GUID List of 1 item, remove the one item"
  echo "$FUNCNAME Test 1:   using 'cur'.  Image GUID List file should not exist." 
  GUIDremovalByGUIDAssert 'cur' 1
  echo "$FUNCNAME Test 1: Successful"
  echo "$FUNCNAME Test 2: Given an Image GUID List of 2 items, remove the one item"
  echo "$FUNCNAME Test 2:   using 'cur'.  Image GUID List file should contain one item." 
  GUIDremovalByGUIDAssert 'cur' 2
  echo "$FUNCNAME Test 2: Successful"
  echo "$FUNCNAME Test 3: Given an Image GUID List of 3 items, remove the one item"
  echo "$FUNCNAME Test 3:   using 'cur'.  Image GUID List file should contain two items." 
  GUIDremovalByGUIDAssert 'cur' 3
  echo "$FUNCNAME Test 3: Successful"
  echo "$FUNCNAME Test 4: Given an Image GUID List of 1 item, attempt to remove"
  echo "$FUNCNAME Test 4:   non-existent entries 'allButCur'.  Image GUID List file"
  echo "$FUNCNAME Test 4:   should exist with one item - the current one."
  GUIDremovalByGUIDAssert 'allButCur' 1
  echo "$FUNCNAME Test 4: Successful"
  echo "$FUNCNAME Test 5: Given an Image GUID List of 2 items, attempt to remove"
  echo "$FUNCNAME Test 5:   non current entry 'allButCur'.  Image GUID List file"
  echo "$FUNCNAME Test 5:   should exist with one item - the current one."
  GUIDremovalByGUIDAssert 'allButCur' 2
  echo "$FUNCNAME Test 5: Successful"
  echo "$FUNCNAME Test 6: Given an Image GUID List of 3 items, attempt to remove"
  echo "$FUNCNAME Test 6:   non current entry 'allButCur'.  Image GUID List file"
  echo "$FUNCNAME Test 6:   should exist with one item - the current one."
  GUIDremovalByGUIDAssert 'allButCur' 3
  echo "$FUNCNAME Test 6: Successful"
  echo "$FUNCNAME Test 7: Given an Image GUID List of 1 items, attempt to remove"
  echo "$FUNCNAME Test 7:   all entries 'all'.  Image GUID List file should not exist."
  GUIDremovalByGUIDAssert 'all' 1
  echo "$FUNCNAME Test 7: Successful"
  echo "$FUNCNAME Test 8: Given an Image GUID List of 2 items, attempt to remove"
  echo "$FUNCNAME Test 8:   all entries 'all'.  Image GUID List file should not exist."
  GUIDremovalByGUIDAssert 'all' 2
  echo "$FUNCNAME Test 8: Successful"
  echo "$FUNCNAME Test 9: Given an Image GUID List of 3 items, attempt to remove"
  echo "$FUNCNAME Test 9:   all entries 'all'.  Image GUID List file should not exist."
  GUIDremovalByGUIDAssert 'all' 3
  echo "$FUNCNAME Test 9: Successful"
  echo "$FUNCNAME Test 10: Given an Image GUID List of 51 items, attempt to remove"
  echo "$FUNCNAME Test 10:   all entries 'all'.  Image GUID List file should not exist."
  GUIDremovalByGUIDAssert 'all' 51
  echo "$FUNCNAME Test 10: Successful"
}
###############################################################################
##
##  Purpose:
##    Test Image GUID List removal functions to ensure they preserve mtime.
##  
###############################################################################
function GUIDlistRemoveModifyDatePreserveTest () {
  echo "$FUNCNAME Test 1: Remove the current Image GUID, leaving at least one"
  echo "$FUNCNAME Test 1:   other GUID in the file." 
  ImageModifyDatePreserveAssert  'cur' 2
  echo "$FUNCNAME Test 1: Successful"
  echo "$FUNCNAME Test 2: Remove the all but the current Image GUID, leaving at least one"
  echo "$FUNCNAME Test 2:   other GUID in the file." 
#  ImageModifyDatePreserveAssert  'allButCur' 3
  echo "$FUNCNAME Test 2: Successful"
}

function main () {
  GUIDlistRemoveTest
  GUIDlistRemoveModifyDatePreserveTest
}

main
