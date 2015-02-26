#!/bin/bash
source "MessageInclude.sh";
source "ArrayMapTestInclude.sh";

function AssociativeMapFromBufferTest () {

  echo "$FUNCNAME Test 1: Simple one element packet."
  local packet='3/Key5/value'
  unset fieldNameMap
  declare -A fieldNameMap
  AssociativeMapFromBuffer "$packet" 'fieldNameMap'
  AssociativeMapAssertKeyValue $LINENO 'fieldNameMap' 'Key' 'value'
  echo "$FUNCNAME Test 1: Successful"

  echo "$FUNCNAME Test 2: Two element packet."
  local packet='3/Key5/value4/Key26/value2'
  unset fieldNameMap
  declare -A fieldNameMap
  AssociativeMapFromBuffer "$packet" 'fieldNameMap'
  AssociativeMapAssertKeyValue $LINENO 'fieldNameMap' 'Key' 'value' 'Key2' 'value2'
  echo "$FUNCNAME Test 2: Successful"

  echo "$FUNCNAME Test 3: Three element packet.  Third element encapsulates another packet."
  local packet='3/Key5/value4/Key26/value24/Key314/4/Key46/value4'
  unset fieldNameMap
  declare -A fieldNameMap
  AssociativeMapFromBuffer "$packet" 'fieldNameMap'
  AssociativeMapAssertKeyValue $LINENO 'fieldNameMap' 'Key' 'value' 'Key2' 'value2' 'Key3' '4/Key46/value4'
  echo "$FUNCNAME Test 3: Successful"

  local packet='12/PacketHeader12/PacketHeader20/ComponentContextPath57//home/dlw/project/sample/component/dlw_apache/context/run13/ComponentName10/dlw_apache17/ImageGUIDFileName50//home/dlw/project/sample/image/dlw_apache.GUIDlist20/ComponentDescription0/9/ImageGUID12/a59c9799043c13/DockerCommand72/docker run -d -i --name dlw_apache --link dlw_mysql:mysql a59c9799043c  '
  echo "$FUNCNAME Test 4: Real generated packet that failed."
  unset fieldNameMap
  declare -A fieldNameMap
  AssociativeMapFromBuffer "$packet" 'fieldNameMap'
  AssociativeMapAssertKeyValue $LINENO 'fieldNameMap' 'PacketHeader' 'PacketHeader' 'DockerCommand' 'docker run -d -i --name dlw_apache --link dlw_mysql:mysql a59c9799043c  '
  echo "$FUNCNAME Test 4: Successful"
}

function AssociativeMapToBufferTest () {

  echo "$FUNCNAME Test 1: Simple one element map."
  unset fieldNameMap
  declare -A fieldNameMap
  fieldNameMap['Key']='value'
  if [ '3/Key5/value' != "`AssociativeMapToBuffer 'fieldNameMap'`" ]; then echo problem; exit 1; fi
  AssociativeMapAssertKeyValue $LINENO 'fieldNameMap' 'Key' 'value'
  echo "$FUNCNAME Test 1: Successful"

  echo "$FUNCNAME Test 2: Two element map."
  unset fieldNameMap
  declare -A fieldNameMap
  fieldNameMap['Key2']='value2'
  fieldNameMap['Key']='value'
  if [ '4/Key26/value23/Key5/value' != "`AssociativeMapToBuffer 'fieldNameMap'`" ]; then echo problem; exit 1; fi
  AssociativeMapAssertKeyValue $LINENO 'fieldNameMap' 'Key' 'value' 'Key2' 'value2'
  echo "$FUNCNAME Test 2: Successful"

  echo "$FUNCNAME Test 3: Three element packet.  Third element encapsulates another packet."
  unset fieldNameMap
  declare -A fieldNameMap
  fieldNameMap['Key3']='4/Key46/value4'
  fieldNameMap['Key2']='value2'
  fieldNameMap['Key']='value'
  if [ '4/Key314/4/Key46/value44/Key26/value23/Key5/value' != "`AssociativeMapToBuffer 'fieldNameMap'`" ]; then echo problem; exit 1; fi
  AssociativeMapAssertKeyValue $LINENO 'fieldNameMap' 'Key' 'value'  'Key2' 'value2' 'Key3' '4/Key46/value4'
  echo "$FUNCNAME Test 3: Successful"

  echo "$FUNCNAME Test 4: One element packet with trailing spaces."
  unset fieldNameMap
  declare -A fieldNameMap
  fieldNameMap['Key']='value      '
  if [ '3/Key11/value      ' != "`AssociativeMapToBuffer 'fieldNameMap'`" ]; then echo problem; exit 1; fi
  AssociativeMapAssertKeyValue $LINENO 'fieldNameMap' 'Key' 'value      '
  echo "$FUNCNAME Test 4: Successful"
}

function main () { 
  AssociativeMapFromBufferTest
  AssociativeMapToBufferTest
}

main

