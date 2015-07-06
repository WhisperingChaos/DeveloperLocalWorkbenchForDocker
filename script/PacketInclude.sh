#!/bin/bash
###############################################################################
##
##  Purpose:
##    Modules provides methods to manage a "Packet".  A packet represents
##    a serialized form of field name (key) and associated field value pairs.
##    This serialized form is a string type that adheres to the packet format
##    presented below.
##    
##    Packets can be composite/recursive.
##    
##  Packet Format:
##    <lengthOfFieldName>/<fieldName><lengthOfFieldValue>/<fieldValue>...
##
##    <lengthOfFieldName> - Total length in bytes of the field name field.
##    <fieldName> - Value representing the name of the field.
##    <lengthOfFieldValue> - The length of the field value associated to the fieldName.
##    <fieldValue> - The string associated to the fieldName.
##
##    Example:
##       Packet: '9/FieldName10/FieldValue10/FieldName211/FieldValue2'
##       field Name & value:  'FieldName' 'FieldValue' 'FieldName2' 'FieldValue2'
##
###############################################################################
##
###############################################################################
##
##  Purpose:
##    Create a packet given one or more field & value parings.
##    
##  Input:
##    $1 - Field Name  - meta data tag
##    $2 - Field Value - The named field's value
##    $odd  - Field Name
##    $even - Field Value
##    $N - variable to receive the result.
## 
##  Output:
##    When Successful:
##      $N - Contains new packet.
##
###############################################################################
function PacketCreateFromStrings () {
  PacketAddFromStrings '' "${@}"
}
###############################################################################
##
##  Purpose:
##    Add one or more fields to a null or existing packet.  The add appends
##    fields and their values to the packet.
##
##  Note:
##    If the same attribute name appears more than once in the packet,
##    its deserialized value will be determined by the data type it 
##    becomes.  For example, since a packet is typically deserialized
##    as bash associative array, the value associated to the duplicate
##    attribute name, neatest the packet's end will be assigned to the
##    attribute name (key) of the map.
##    
##  Input:
##    $1 - Existing or null packet.  Use '' to specify null packet.
##    $2 - Field Name  - meta data tag
##    $3 - Field Value - The named field's value
##    $even  - Field Name
##    $odd - Field Value
##    $N - variable to receive the result.
## 
##  Output:
##    When Successful:
##      $N - Contains packet's old contents with the additional field.
##
###############################################################################
function PacketAddFromStrings () {
  local packetAddFirst="$1"
  shift
  local -i stringArgCnt=$(( $# - 1 ))
  if [ "$(( stringArgCnt % 2))" -ne '0' ]; then ScriptUnwind $LINENO "Should be corresponding number of field name and values passed as arguments to create packet or missing output argument."; fi 
  local packetAddThese
  for (( stringArgCnt ; stringArgCnt > 0; stringArgCnt-=2 )) do
    packetAddThese+="${#1}/${1}${#2}/$2"
    shift 2
  done
  if [ -n "$packetAddFirst" ]; then
    PacketBodyExtract "$packetAddFirst" 'packetAddFirst'
  fi
  # $1 should reflect the name of the return variable
  PacketEncapsulate "${packetAddFirst}${packetAddThese}" "$1"
}
###############################################################################
##
##  Purpose:
##    Convert a Packet into its constituent field name and field value pairs.
##    
##  Input:
##    $1 - An existing Packet.
## 
##  Output:
##    When Successful:
##      SYSOUT - Single line of output with each field name and its associated
##               value individually separated by a single whitespace and
##               enclosed in single quotes:
##        Ex:  'FieldName' 'FieldValue' 'FieldName2' FieldValue2'
##
###############################################################################
function PacketConvetToStrings () {
  ScriptUnwind $LINENO "$FUNCNAME not yet implemented."
}
##############################################################################
##
##  Purpose:
##    Given an associative array, serialize its contents to a packet.
##    
##  Assumptions:
##    All bash variable names supplied as arguments to this function, like
##    the associative array, have been declared within a scope that 
##    includes this function.
##
##    The variable name of the associative array isn't the same as any
##    local variable name declared by this routine.
##
##  Input:
##    $1 - Variable name of bash associative array whose keys will
##         reflect a packet's field name while its values reflect field values.
##    $2 - Variable name to receive resultant packet.
## 
##  Outputs:
##    When Successful:
##      $2 contains well formed packet.
##
###############################################################################
function PacketCreateFromAssociativeMap () {
  local packetCreateSerializedMap
  AssociativeMapToBuffer "$1" 'packetCreateSerializedMap'
  PacketEncapsulate "$packetCreateSerializedMap" "$2"
}
##############################################################################
##
##  Purpose:
##    Given a packet, convert its contents into an associative array.
##    
##  Buffer/String Format:
##    see function: AssociativeMapToBuffer
##
##  Assumptions:
##    All bash variable names supplied as arguments to this function, like
##    the associative array, have been declared within a scope that 
##    includes this function.
##
##    The variable name of the associative array isn't the same as any
##    local variable name declared by this routine.
##
##    Duplicate key values will overlay last key-value.  The last key-value
##    pairs are ordered from first/leftmost to last/rightmost.
##
##  Input:
##    $1 - Buffer contaiing array serialize in format described above.
##    $2 - Variable name to bash associative array that will be assigned
##         the key value pairs located in the serialized buffer.
##         Note - This routine preserves key value pairs that already
##         exist in the array, unless key names overlap.
## 
##  Output:
##    When Successful:
##      $2 - Contains new key value pairs.
##
#################################################################################
function PacketConvertToAssociativeMap  () {
  local packetConvBodyMap
  PacketBodyExtract "$1" 'packetConvBodyMap'
  AssociativeMapFromBuffer "$packetConvBodyMap" "$2"
}
##############################################################################
##
##  Purpose:
##    Encapsulate a packet body within a preamble and terminator.
##    
##  Buffer/String Format:
##    see function: AssociativeMapToBuffer
##
##  Assumptions:
##    All bash variable names supplied as arguments to this function, like
##    the associative array, have been declared within a scope that 
##    includes this function.
##
##    The variable name of the associative array isn't the same as any
##    local variable name declared by this routine.
##
##    Duplicate key values will overlay last key-value.  The last key-value
##    pairs are ordered from first/leftmost to last/rightmost.
##
##  Input:
##    $1 - String a packet body serialize in format described above.
##    $2 - Bash variable to assign resultant encapsulated packet.
## 
##  Output:
##    When Successful:
##      $2 - Contains a properly encapsulated packet.
##
#################################################################################
function PacketEncapsulate () {
  local -r packetEncBody="$1"
  local -r packetEncReturnNm="$2"
  local packetEncPreample
  PacketPreambleGet 'packetEncPreample'
  local packetEncTerminator
  PacketTerminatorGet 'packetEncTerminator'
  eval $packetEncReturnNm=\"\$\{packetEncPreample\}\$\{packetEncBody\}\$\{packetEncTerminator\}\"
}
##############################################################################
##
##  Purpose:
##    Concatenate one or more packets into a cohesive packet.
##    
##  Buffer/String Format:
##    see function: AssociativeMapToBuffer
##
##  Assumptions:
##    All bash variable names supplied as arguments to this function, like
##    the associative array, have been declared within a scope that 
##    includes this function.
##
##    The variable name of the associative array isn't the same as any
##    local variable name declared by this routine.
##
##    Duplicate key values will overlay last key-value.  The last key-value
##    pairs are ordered from first/leftmost to last/rightmost.
##
##  Input:
##    $1-$(N-1) - Buffer contaiing array serialize in format described above.
##    $2 - Output buffer to assign new buffer to
## 
##  Output:
##    When Successful:
##      $2 - Contains new key value pairs.
##
#################################################################################
function PacketCat () {
  if [ "$#" -lt '3' ]; then ScriptUnwind $LINENO "Packet concatenation requres at least three arguments"; fi
  local packetCatResult
  while [ "$#" -gt '1' ]; do
    local packetCatBody
    PacketBodyExtract "$1" 'packetCatBody'
    packetCatResult+="$packetCatBody"
    shift
  done
  # $1 should contain variable name to return newly formed packet. 
  if PacketPreambleMatch "$1"; then ScriptUnwind $LINENO "Missing return variable at end of argument list."; fi
  PacketEncapsulate "$packetCatResult" "$1"
  return 0
}
##############################################################################
##
##  Purpose:
##    Expose the body of a packet by removing its heading and terminating
##    fields.
##    
##  Buffer/String Format:
##    see function: AssociativeMapToBuffer
##
##  Assumptions:
##    All bash variable names supplied as arguments to this function, like
##    the associative array, have been declared within a scope that 
##    includes this function.
##
##    The variable name of the associative array isn't the same as any
##    local variable name declared by this routine.
##
##  Input:
##    $1 - Well formed packet.
##    $2 - Varaible name to accept the packet's body.
## 
##  Output:
##    When Successful:
##      $2 - assigned the packet's body.
##
#################################################################################
function PacketBodyExtract () {
  local -r packetBodyExtNm="$2"
  local packetBodyExtPreample
  PacketPreambleGet 'packetBodyExtPreample'
  local -r -i packetBodyExtPreampleSize=${#packetBodyExtPreample}
  local packetBodyExtTerm
  PacketTerminatorGet 'packetBodyExtTerm'
  local -r -i packetBodyExtTermSize=${#packetBodyExtTerm}
  if ! PacketPreambleMatch   "$1"; then ScriptUnwind $LINENO "Packet: '$1' lacks conforming preamble."; fi
  if ! PacketTerminatorMatch "$1"; then ScriptUnwind $LINENO "Packet: '$1' lacks conforming packetBodyExtTerm."; fi
  # remove existing preamble and terminator and expose packet body
  eval $packetBodyExtNm=\"\$\{\1\:\$packetBodyExtPreampleSize\:\$\{\#\1\}\ \-\ \$packetBodyExtPreampleSize\ \-\ \$packetBodyExtTermSize\}\"
  return 0
}
##############################################################################
##
##  Purpose:
##    Test buffer to determine if it's preamble conforms to a packet header.
##    A packet header refers to the first field name and its value.
##
##  Assume:
##    If either default or specified header field name and value,
##    and packet control data for these elements are correct, then
##    buffer is considered to contain a packet without testing the
##    remaining control data flields.
##    
##  Expected Buffer/String Format:
##    see function: AssociativeMapToBuffer
##
##  Input:
##    $1 - Buffer contaiing array serialize in format described above.
##
##  Output:
##    When True:
##      $? = 0
##
#################################################################################
function PacketPreambleMatch  () {
  local packetPreampleMatch
  PacketPreambleGet 'packetPreampleMatch'
  if [ "${1:0:${#packetPreampleMatch}}" != "$packetPreampleMatch" ]; then return 1; fi
  return 0
}
##############################################################################
##
##  Purpose:
##    Assign a common prefix to a packet so it can be descerned from other
##    data being streamed through a pipe and to provide the starting bookend
##    to an encapsulated packet body.  
##
##  Assume:
##    The packet serialization format won't change, otherwise, this statically
##    generated snipped will cause failures.
##
##    All bash variable names supplied as arguments to this function, like
##    $1 have been declared within a subshell that includes this function.
##
##    The variable name of $1 isn't the same as any
##    local variable name declared by this routine.
##    
##    The packet serialization format won't change.
##    
##  Expected Buffer/String Format:
##    see function: AssociativeMapToBuffer
##
##  Input:
##    $1 - Variable name to receive the packet preample snippet.
##
##  Output:
##    $1 - Variable name will be assigned preample snippet.
##
#################################################################################
function PacketPreambleGet  () {
  eval $1\=\'12\/PacketHeader12\/PacketHeader\'
  return 0
}
##############################################################################
##
##  Purpose:
##    Test buffer to determine if it's terminator conforms to a packet
##    terminator.  A terminator should end every packet. its value.
##
##  Expected Buffer/String Format:
##    see function: AssociativeMapToBuffer
##
##  Input:
##    $1 - Buffer contaiing array serialize in format described above.
##
##  Output:
##    When True:
##      $? = 0
##
#################################################################################
function PacketTerminatorMatch () {
  local packetTermMatch
  PacketTerminatorGet 'packetTermMatch'
  if [ "${1:(-${#packetTermMatch})}" != "$packetTermMatch" ]; then return 1; fi
  return 0
}
##############################################################################
##
##  Purpose:
##    Assign a common suffix to a packet so it can prevent linux read commands
##    from erroreously removing trailing whitespace from the packet body.
##
##  Assume:
##    The packet serialization format won't change, otherwise, this statically
##    generated snipped will cause failures.
##
##    All bash variable names supplied as arguments to this function, like
##    $1 have been declared within a subshell that includes this function.
##
##    The variable name of $1 isn't the same as any
##    local variable name declared by this routine.
##    
##    The packet serialization format won't change.
##
##    The packet terminator value must be devoid of trailing whitespace 
##    
##  Expected Buffer/String Format:
##    see function: AssociativeMapToBuffer
##
##  Input:
##    $1 - Variable name to receive the packet terminator snippet.
##
##  Output:
##    $1 - Variable name will be assigned terminator snippet.
##
#################################################################################
function PacketTerminatorGet () {
  eval $1\=\'9\/PacketEnd9\/PacketEnd\'
  return 0
}
##############################################################################
##
##  Purpose:
##    Trim leading and trailing whitespace from provided variable.
##
##  Assume:
##    If either default or specified header field name and value,
##    and packet control data for these elements are correct, then
##    buffer is considered to contain a packet without testing the
##    remaining control data flields.
##    
##  Expected Buffer/String Format:
##    see function: AssociativeMapToBuffer
##
##  Input:
##    $1 - Variable whose contents will be trimmed of whitespace.
##
##  Output:
##    $1 - Variable whose contents will be trimmed of whitespace.
##
#################################################################################
WhitespaceTrim() {
    local varNm="$1"
    eval $varNm=\"\$\{$varNm\#\"\$\{$varNm\%\%\[\!\[\:\s\p\a\c\e\:\]\]\*\}\"\}\"   # remove leading whitespace characters
    eval $varNm=\"\$\{$varNm\%\"\$\{$varNm\#\#\*\[\!\[\:\s\p\a\c\e\:\]\]\}\"\}\"   # remove trailing whitespace characters
}
##############################################################################
##
##  Purpose:
##    Replace all single quotes with provided character string.
##
##  Input:
##    String with single quotes.
##
##  Output:
##    SYSOUT - String with all its single quotes replced.
##
#################################################################################
QuoteSingleReplace() {
    echo "${1//\'/$2}"
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
