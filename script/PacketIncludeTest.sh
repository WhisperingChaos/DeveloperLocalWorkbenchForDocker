#!/bin/bash
source "MessageInclude.sh";
source "ArrayMapTestInclude.sh";
source "PacketInclude.sh";

function PacketCreateFromStringsTest () {

  echo "$FUNCNAME Test 1: Create a single field packet."
  local packet
  PacketCreateFromStrings 'FieldName' 'FieldValue' 'packet'
  if ! [ '12/PacketHeader12/PacketHeader9/FieldName10/FieldValue9/PacketEnd9/PacketEnd' == "$packet" ]; then
    ScriptUnwind $LINENO "Test should have successfully completed.";
  fi
  echo "$FUNCNAME Test 1: Successful"

  echo "$FUNCNAME Test 2: Create a two field packet using strings"
  local packet
  PacketCreateFromStrings 'FieldName' 'FieldValue' 'FieldName2' 'FieldValue2' 'packet'
  if ! [ '12/PacketHeader12/PacketHeader9/FieldName10/FieldValue10/FieldName211/FieldValue29/PacketEnd9/PacketEnd' == "$packet" ]; then
    ScriptUnwind $LINENO "Test should have successfully completed.";
  fi
  echo "$FUNCNAME Test 2: Successful"

  echo "$FUNCNAME Test 3: Attempt to create a packet that consists of an entry of only a field name - should fail"
  local packet
  if `PacketCreateFromStrings 'FieldName' 'FieldValue' 'FieldName2' 'packet'`; then
    ScriptUnwind $LINENO "Test should have failed.";
  fi
  echo "$FUNCNAME Test 3: Successful"

  echo "$FUNCNAME Test 4: Attempt to create a packet that consists a field name that's associated to a null string"
  local packet
  PacketCreateFromStrings 'FieldName' 'FieldValue' 'FieldNa"me2' '' 'packet'
  if ! [ '12/PacketHeader12/PacketHeader9/FieldName10/FieldValue11/FieldNa"me20/9/PacketEnd9/PacketEnd' == "$packet" ]; then
    ScriptUnwind $LINENO "Test should have successfully completed.";
  fi
  echo "$FUNCNAME Test 4: Successful"

  echo "$FUNCNAME Test 5: forget to put the receiving buffer at the end of the create"
  local packet
  if `PacketCreateFromStrings 'FieldName' 'FieldValue' 'FieldNa"me2' ''`; then  
    ScriptUnwind $LINENO "Test should have failed with appropiate message.";
  fi
  echo "$FUNCNAME Test 5: Successful"
}

function PacketAddFromStringsTest () {
  # Since PacketCreateFromStrings is simply a wrapper for the PacketAddFromStrings only basic argument positioning testing performed.
  echo "$FUNCNAME Test 1: Create a single field packet by adding a single field to a empty packet."
  local packet
  PacketAddFromStrings '' 'FieldName' 'FieldValue' 'packet'
  if ! [ '12/PacketHeader12/PacketHeader9/FieldName10/FieldValue9/PacketEnd9/PacketEnd' == "$packet" ]; then
    ScriptUnwind $LINENO "Test should have successfully completed.";
  fi
  echo "$FUNCNAME Test 1: Successful"
 
  echo "$FUNCNAME Test 2: Add a second set of fileds to an existing packet."
  local packet
  PacketAddFromStrings '12/PacketHeader12/PacketHeader9/FieldName10/FieldValue9/PacketEnd9/PacketEnd' 'FieldName2' 'FieldValue2' 'packet'
  if ! [ '12/PacketHeader12/PacketHeader9/FieldName10/FieldValue10/FieldName211/FieldValue29/PacketEnd9/PacketEnd' == "$packet" ]; then
    ScriptUnwind $LINENO "Test should have successfully completed.";
  fi
  echo "$FUNCNAME Test 2: Successful"
}

PacketCreateFromAssociativeMapTest () {
  # Since PacketCreateFromAssociativeMap is nearly a wrapper for AssociativeMapToBuffer only basic argument positioning testing performed.
  echo "$FUNCNAME Test 1: Two element map."
  unset fieldNameMap
  declare -A fieldNameMap
  fieldNameMap['Key2']='value2'
  fieldNameMap['Key']='value'
  AssociativeMapAssertKeyValue $LINENO 'fieldNameMap' 'Key' 'value' 'Key2' 'value2'
  local packet
  PacketCreateFromAssociativeMap 'fieldNameMap' 'packet'
  if [ '12/PacketHeader12/PacketHeader4/Key26/value23/Key5/value9/PacketEnd9/PacketEnd' != "$packet" ]; then
    ScriptUnwind $LINENO "Test should have successfully completed."
  fi
  echo "$FUNCNAME Test 1: Successful"
}

function PacketConvertToAssociativeMapTest () {
  # Since PacketCreateFromAssociativeMap is nearly a wrapper for AssociativeMapToBuffer only basic argument positioning testing performed.
  echo "$FUNCNAME Test 1: Two element packet to map."
  unset fieldNameMap
  declare -A fieldNameMap
  if ! PacketConvertToAssociativeMap '12/PacketHeader12/PacketHeader4/Key26/value23/Key5/value9/PacketEnd9/PacketEnd' 'fieldNameMap'; then
    ScriptUnwind $LINENO "Test should have successfully completed.";
  fi
  AssociativeMapAssertKeyValue $LINENO 'fieldNameMap' 'Key' 'value' 'Key2' 'value2'
  echo "$FUNCNAME Test 1: Successful"
}

function PacketPreambleMatchTest () {

  echo "$FUNCNAME Test 1: Test preamble detection."
  local packet
  PacketCreateFromStrings 'FieldName' 'FieldValue' 'packet'
  if ! PacketPreambleMatch "$packet"; then ScriptUnwind $LINENO "Test should have successfully completed."; fi
  echo "$FUNCNAME Test 1: Successful"

  echo "$FUNCNAME Test 2: Test failure of preamble detection."
  if PacketPreambleMatch "gabarage"; then  ScriptUnwind $LINENO "Test should have failed."; fi
  echo "$FUNCNAME Test 2: Successful"
}

function PacketTerminatorMatchTest () {

  echo "$FUNCNAME Test 1: Test termination detection."
  local packet
  PacketCreateFromStrings 'FieldName' 'FieldValue' 'packet'
  if ! PacketTerminatorMatch "$packet"; then ScriptUnwind $LINENO "Test should have successfully completed."; fi
  echo "$FUNCNAME Test 1: Successful"

  echo "$FUNCNAME Test 2: Test failure of packet termination detection."
  if PacketTerminatorMatch "gabarage"; then  ScriptUnwind $LINENO "Test should have failed."; fi
  echo "$FUNCNAME Test 2: Successful"
}

function PacketCatTest () {

  echo "$FUNCNAME Test 1: Test termination detection."
  local packet1
  PacketCreateFromStrings 'FieldName' 'FieldValue' 'packet1'
  local packet2
  PacketCreateFromStrings 'FieldName' 'FieldValue' 'packet2'
  local packetResult
  PacketCat "$packet1" "$packet2" 'packetResult'
  if [ '12/PacketHeader12/PacketHeader9/FieldName10/FieldValue9/FieldName10/FieldValue9/PacketEnd9/PacketEnd' != "$packetResult" ]; then
    ScriptUnwind $LINENO "Test should have successfully completed."
  fi
  echo "$FUNCNAME Test 1: Successful"

  echo "$FUNCNAME Test 2: Test failure mode where expected packet isn't one."
  local packet1
  PacketCreateFromStrings 'FieldName' 'FieldValue' 'packet1'
  local packetResult
  if `PacketCat "$packet1" "garbarage" 'packetResult'`; then
    ScriptUnwind $LINENO "Test should have failed."
  fi
  echo "$FUNCNAME Test 2: Successful"

  echo "$FUNCNAME Test 3: Test failure mode when missing return variable."
  local packet1
  PacketCreateFromStrings 'FieldName' 'FieldValue' 'packet1'
  local packet2
  PacketCreateFromStrings 'FieldName' 'FieldValue' 'packet2'
  local packetResult
  if `PacketCat "$packet1" "$packet2" "$packet1" "$packet2"`; then
    ScriptUnwind $LINENO "Test should have failed."
  fi
  echo "$FUNCNAME Test 3: Successful"
}

function main () {
  if ! PacketCreateFromStringsTest;        then ScriptUnwind $LINENO "Unexpected return code: '$?', should be '0'"; fi
  if ! PacketAddFromStringsTest;           then ScriptUnwind $LINENO "Unexpected return code: '$?', should be '0'"; fi
  if ! PacketCreateFromAssociativeMapTest; then ScriptUnwind $LINENO "Unexpected return code: '$?', should be '0'"; fi
  if ! PacketConvertToAssociativeMapTest;  then ScriptUnwind $LINENO "Unexpected return code: '$?', should be '0'"; fi
  if ! PacketPreambleMatchTest;            then ScriptUnwind $LINENO "Unexpected return code: '$?', should be '0'"; fi
  if ! PacketCatTest;                      then ScriptUnwind $LINENO "Unexpected return code: '$?', should be '0'"; fi
}

main
