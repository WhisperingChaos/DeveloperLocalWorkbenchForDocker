#!/bin/bash
source "MessageInclude.sh";
source "ArgumentsGetInclude.sh";
source "ArrayMapTestInclude.sh";
###############################################################################
##
##  Purpose:
##    Test Option/Argument parsing algorithm.
##
##  Outputs:   
##    When Failure: 
##      Identifies test, line numbers and reason for failure.
##
###############################################################################
function ArgumentsParseTest () {
  function ArgumentsParseTestCmmdLn () {
    function main () {
      declare -A ArgMap
      declare -a ArgList
      VirtArgumentsParseTest_Desc 
      if ! ArgumentsParse 'mainArgumentList' ArgList ArgMap ; then ScriptUnwind $LINENO "Expected success but encountered failure"; fi
      VirtArgumentsParseTest_Audit 
    }
    source "ArgumentsMainInclude.sh";
  }
  function VirtArgumentsParseTest_Desc () {
    echo "$FUNCNAME Test 1: 2 short options followed by 1 long one."
    echo "$FUNCNAME Test 1:   then a compound short option with an associated value"
    echo "$FUNCNAME Test 1:   ending with a single stand alone argument" 
  }
  function VirtArgumentsParseTest_Audit () { 
    AssociativeMapAssertKeyValue $LINENO 'ArgMap' '-a' '' '-b' '' '--purge' 'yes' '-cde' 'hello there' 'Arg1' 'mysql'
    ArrayAssertValues $LINENO 'ArgList' '-a' '-b' '--purge' '-cde' 'Arg1'
    echo "$FUNCNAME Test 1: Successful"
  }
  ArgumentsParseTestCmmdLn -a -b --purge=yes -cde="hello there" mysql
  function VirtArgumentsParseTest_Desc () {
    echo 
    echo "$FUNCNAME Test 2: 2 short options followed by 1 long one then '--' to force"
    echo "$FUNCNAME Test 2:   remaining arguments to be treated as plain arguments even though"
    echo "$FUNCNAME Test 2:   they may start with hypnens"
  }
  function VirtArgumentsParseTest_Audit () { 
    AssociativeMapAssertKeyValue $LINENO 'ArgMap' '-a' '' '-b' '' '--purge' 'yes' 'Arg1' '-abc=hello there' 'Arg2' 'mysql'
    ArrayAssertValues $LINENO 'ArgList' '-a' '-b' '--purge' 'Arg1' 'Arg2'
    echo "$FUNCNAME Test 2: Successful"
  }
  ArgumentsParseTestCmmdLn -a -b --purge=yes -- -abc="hello there" mysql
  function VirtArgumentsParseTest_Desc () {
    echo
    echo "$FUNCNAME Test 3: 1 short option followed by '-' to force"
    echo "$FUNCNAME Test 3:   remaining arguments to be treated as plain arguments even though"
    echo "$FUNCNAME Test 3:   they may start with hypnens" 
  }
  function VirtArgumentsParseTest_Audit () { 
    AssociativeMapAssertKeyValue $LINENO 'ArgMap' '-a' '' 'Arg1' '-abc=hello there' 'Arg2' 'mysql'
    ArrayAssertValues $LINENO 'ArgList' '-a' 'Arg1' 'Arg2'
    echo "$FUNCNAME Test 3: Successful"
  }
  ArgumentsParseTestCmmdLn -a - -abc="hello there" mysql
  function VirtArgumentsParseTest_Desc () {
    echo
    echo "$FUNCNAME Test 4: 1 short option and '-'at end"
  }
  function VirtArgumentsParseTest_Audit () { 
    AssociativeMapAssertKeyValue $LINENO 'ArgMap' '-a' ''
    ArrayAssertValues $LINENO 'ArgList' '-a'
    echo "$FUNCNAME Test 4: Successful"
  }
  ArgumentsParseTestCmmdLn -a -
  function VirtArgumentsParseTest_Desc () {
    echo
    echo "$FUNCNAME Test 5: Argument list: '-a - :'"
    echo "$FUNCNAME Test 5: 1 short option followed by the - to force the remaining" 
    echo "$FUNCNAME Test 5: tokens to be interperted as agruments."
  }
  function VirtArgumentsParseTest_Audit () { 
    AssociativeMapAssertKeyValue $LINENO 'ArgMap' '-a' '' 'Arg1' ':'
    ArrayAssertValues $LINENO 'ArgList' '-a' 'Arg1'
    echo "$FUNCNAME Test 5: Successful"
  }
  ArgumentsParseTestCmmdLn -a - :
  function VirtArgumentsParseTest_Desc () {
    echo
    echo "$FUNCNAME Test 6: Argument list: '-a -- -t -abc=\"5\" --'"
    echo "$FUNCNAME Test 6: 1 short option followed by '--' to force the remaining" 
    echo "$FUNCNAME Test 6: tokens to be interperted as agruments."
  }
  function VirtArgumentsParseTest_Audit () { 
    AssociativeMapAssertKeyValue $LINENO 'ArgMap' '-a' '' 'Arg1' '-t' 'Arg2' '-abc=5' 'Arg3' '--'
    ArrayAssertValues $LINENO 'ArgList' '-a' 'Arg1' 'Arg2' 'Arg3'
    echo "$FUNCNAME Test 6: Successful"
  }
  ArgumentsParseTestCmmdLn -a -- -t -abc="5" --
  function VirtArgumentsParseTest_Desc () {
    echo
    echo "$FUNCNAME Test 7: Argument list: '-a --purge =\"no\"'"
    echo "$FUNCNAME Test 7: 1 short option followed by a long option with whitespace"
    echo "$FUNCNAME Test 7: between the long option and assignment operator." 
  }
  function VirtArgumentsParseTest_Audit () { 
    AssociativeMapAssertKeyValue $LINENO 'ArgMap' '-a' '' '--purge' '="no"'
    ArrayAssertValues $LINENO 'ArgList' '-a' '--purge'
    echo "$FUNCNAME Test 7: Successful"
  }
  ArgumentsParseTestCmmdLn -a --purge =\"no\"
  function VirtArgumentsParseTest_Desc () {
    echo
    echo "$FUNCNAME Test 8: Argument list: '=no'"
    echo "$FUNCNAME Test 8: 1 argument." 
  }
  function VirtArgumentsParseTest_Audit () { 
    AssociativeMapAssertKeyValue $LINENO 'ArgMap' 'Arg1' '=no'
    ArrayAssertValues $LINENO 'ArgList' 'Arg1'
    echo "$FUNCNAME Test 8: Successful"
  }
  ArgumentsParseTestCmmdLn =no
  function VirtArgumentsParseTest_Desc () {
    echo
    echo "$FUNCNAME Test 9: Argument list: '-- =no'"
    echo "$FUNCNAME Test 9: 1 argument." 
  }
  function VirtArgumentsParseTest_Audit () { 
    AssociativeMapAssertKeyValue $LINENO 'ArgMap' 'Arg1' '=no'
    ArrayAssertValues $LINENO 'ArgList' 'Arg1'
    echo "$FUNCNAME Test 9: Successful"
  }
  ArgumentsParseTestCmmdLn -- =no
  function VirtArgumentsParseTest_Desc () {
    echo
    echo "$FUNCNAME Test 10: Argument list: '-a==no'"
    echo "$FUNCNAME Test 10: 1 option" 
  }
  function VirtArgumentsParseTest_Audit () { 
    AssociativeMapAssertKeyValue $LINENO 'ArgMap' '-a' '=no'
    ArrayAssertValues $LINENO 'ArgList' '-a'
    echo "$FUNCNAME Test 10: Successful"
  }
  ArgumentsParseTestCmmdLn -a==no
  function VirtArgumentsParseTest_Desc () {
    echo
    echo "$FUNCNAME Test 11: 2 short options followed by 1 argument."
    echo "$FUNCNAME Test 11:   Arguments are separated by commas"
  }
  function VirtArgumentsParseTest_Audit () { 
    AssociativeMapAssertKeyValue $LINENO 'ArgMap' '-a,' '' '-b,' '' 'Arg1' 'mysql'
    ArrayAssertValues $LINENO 'ArgList' '-a,' '-b,' 'Arg1'
    echo "$FUNCNAME Test 11: Successful"
  }
  ArgumentsParseTestCmmdLn  -a, -b, -- mysql
  function VirtArgumentsParseTest_Desc () {
    echo "$FUNCNAME Test 12: 1 long option that encapsulates another command."
  }
  function VirtArgumentsParseTest_Audit () { 
    AssociativeMapAssertKeyValue $LINENO 'ArgMap' '--dlw' 'hi --dlw=\"hello there\" bye'
    ArrayAssertValues $LINENO 'ArgList' '--dlw'
    echo "$FUNCNAME Test 12: Successful"
  }
  ArgumentsParseTestCmmdLn  --dlw='hi --dlw=\"hello there\" bye'
  function VirtArgumentsParseTest_Desc () {
    echo "$FUNCNAME Test 13: 1 long option that includes single quote."
  }
  function VirtArgumentsParseTest_Audit () { 
    AssociativeMapAssertKeyValue $LINENO 'ArgMap' '--dlw' "hi --dlw=hello' there bye"
    ArrayAssertValues $LINENO 'ArgList' '--dlw'
    echo "$FUNCNAME Test 13: Successful"
  }
  ArgumentsParseTestCmmdLn  --dlw="hi --dlw=hello' there bye"
  function VirtArgumentsParseTest_Desc () {
    echo "$FUNCNAME Test 14: 1 long option that encapsulates another command using double quotes and delimits with \ "
  }
  function VirtArgumentsParseTest_Audit () { 
    AssociativeMapAssertKeyValue $LINENO 'ArgMap' '--dlwc' "watch --dlw=\"hello there bye\""
    ArrayAssertValues $LINENO 'ArgList' '--dlwc'
    echo "$FUNCNAME Test 14: Successful"
  }
  ArgumentsParseTestCmmdLn  --dlwc='watch --dlw="hello there bye"'
  function VirtArgumentsParseTest_Desc () {
    echo "$FUNCNAME Test 15: 1 long option that encapsulates another command with an option '-o' using double quotes and delimits encapsulated double quotes with backslash."
  }
  function VirtArgumentsParseTest_Audit () { 
    AssociativeMapAssertKeyValue $LINENO 'ArgMap' '--dlwc' "watch --dlw=\"hello -o bye\""
    ArrayAssertValues $LINENO 'ArgList' '--dlwc'
    echo "$FUNCNAME Test 15: Successful"
  }
  ArgumentsParseTestCmmdLn  --dlwc='watch --dlw="hello -o bye"'
  function VirtArgumentsParseTest_Desc () {
    echo "$FUNCNAME Test 16: 3 long options.  One option encapsulates another command with both options and arguments using double quotes and delimits encapsulated double quotes with backslash.  While the other two options simply follow this third complex one." 
  }
  function VirtArgumentsParseTest_Audit () { 
    AssociativeMapAssertKeyValue $LINENO 'ArgMap' '--dlwc' "watch --dlwc=\"images -a\"" '--dlwno-exec' '' '--dlwshow' ''
    ArrayAssertValues $LINENO 'ArgList' '--dlwc' '--dlwno-exec' '--dlwshow'
    echo "$FUNCNAME Test 16: Successful"
  }
  ArgumentsParseTestCmmdLn  --dlwc 'watch --dlwc="images -a"' --dlwno-exec --dlwshow
  function VirtArgumentsParseTest_Desc () {
    echo "$FUNCNAME Test 17: using echo without encapsulating with quotes may gobble options like '-n' used by echo."
  }
  function VirtArgumentsParseTest_Audit () { 
    AssociativeMapAssertKeyValue $LINENO 'ArgMap' '-n' '20'
    ArrayAssertValues $LINENO 'ArgList' '-n'
    echo "$FUNCNAME Test 17: Successful"
  }
  ArgumentsParseTestCmmdLn -n 20
}
###############################################################################
##
##  Purpose:
##    Test the functions that normalize the aliases associated to an option.
##
##  Outputs:   
##    When Failure: 
##      Identifies test, line numbers and reason for failure.
##
###############################################################################
function OptionsArgsAliasNormalizeTest () {

  echo "$FUNCNAME Test 1: No aliases defined."
  unset ArgMap
  unset ArgList
  declare -a ArgList
  ArgList+=( '--Test' )
  declare -A ArgMap
  ArgMap['--Test']=''
  OptionsArgsAliasNormalize 'OptionsArgsAliasNormalizeTestDef_Noalias' 'ArgList' 'ArgMap'
  AssociativeMapAssertKeyValue $LINENO 'ArgMap' '--Test' ''
  ArrayAssertValues $LINENO 'ArgList' '--Test'
  echo "$FUNCNAME Test 1: Successful"

  echo "$FUNCNAME Test 2: A single alias defined."
  unset ArgMap
  unset ArgList
  declare -a ArgList
  ArgList+=( '-h' )
  declare -A ArgMap
  ArgMap['-h']='hello'
  OptionsArgsAliasNormalize 'OptionsArgsAliasNormalizeTestDef_help_onealias' 'ArgList' 'ArgMap'
  AssociativeMapAssertKeyValue $LINENO 'ArgMap' '--help' 'hello'
  ArrayAssertValues $LINENO 'ArgList' '--help'
  echo "$FUNCNAME Test 2: Successful"

  echo "$FUNCNAME Test 3: Two aliases defined in table.  Value of -h alias is null string."
  unset ArgMap
  unset ArgList
  declare -a ArgList
  ArgList+=( '-h' )
  declare -A ArgMap
  ArgMap['-h']=''
  OptionsArgsAliasNormalize 'OptionsArgsAliasNormalizeTestDef_help_Twoalias' 'ArgList' 'ArgMap'
  AssociativeMapAssertKeyValue $LINENO 'ArgMap' '--help' ''
  ArrayAssertValues $LINENO 'ArgList' '--help'
  echo "$FUNCNAME Test 3: Successful"

  echo "$FUNCNAME Test 4: Two aliases defined in table.  One is a compound alias of '-h -help'."
  echo "$FUNCNAME Test 4:   Also, if the option is specified twice, or a combination of an option's"
  echo "$FUNCNAME Test 4:   primary and alias names, the most recent one specified, the last"
  echo "$FUNCNAME Test 4:   specified option value, the rightmost on the command line, is used."
  unset ArgMap
  unset ArgList
  declare -a ArgList
  ArgList+=( '--opt1' )
  ArgList+=( '--opt2' )
  ArgList+=( '-help' )
  ArgList+=( '-h' )
  declare -A ArgMap
  ArgMap['--opt1']='--opt1'
  ArgMap['--opt2']='--opt2'
  ArgMap['-help']='-help'
  ArgMap['-h']=''
  OptionsArgsAliasNormalize 'OptionsArgsAliasNormalizeTestDef_help_Compoundalias' 'ArgList' 'ArgMap'
  AssociativeMapAssertKeyValue $LINENO 'ArgMap' '--opt1' '--opt1' '--opt2' '--opt2' '--help' ''
  ArrayAssertValues $LINENO 'ArgList' '--opt1' '--opt2' '--help'
  echo "$FUNCNAME Test 4: Successful"

  echo "$FUNCNAME Test 5: An option's primary name and its alias are specified."
  echo "$FUNCNAME Test 5:   The primary name appears after the alias on the command line,"
  echo "$FUNCNAME Test 5:   therefore the value of the primary should be preserved."
  unset ArgMap
  unset ArgList
  declare -a ArgList
  ArgList+=( '--opt1' )
  ArgList+=( '--opt2' )
  ArgList+=( '-h' )
  ArgList+=( '--help' )
  declare -A ArgMap
  ArgMap['--opt1']='--opt1'
  ArgMap['--opt2']='--opt2'
  ArgMap['-h']='-h'
  ArgMap['--help']='--help'
  OptionsArgsAliasNormalize ' OptionsArgsAliasNormalizeTestDef_help_onealias' 'ArgList' 'ArgMap'
  AssociativeMapAssertKeyValue $LINENO 'ArgMap' '--opt1' '--opt1' '--opt2' '--opt2' '--help' '--help'
  ArrayAssertValues $LINENO 'ArgList' '--opt1' '--opt2' '--help'
  echo "$FUNCNAME Test 5: Successful"

  echo "$FUNCNAME Test 6: An option's primary name and its alias are specified."
  echo "$FUNCNAME Test 6:   The primary name appears before the alias on the command line,"
  echo "$FUNCNAME Test 6:   therefore the value of the alias should be preserved."
  unset ArgMap
  unset ArgList
  declare -a ArgList
  ArgList+=( '--opt1' )
  ArgList+=( '--opt2' )
  ArgList+=( '--help' )
  ArgList+=( '-h' )
  declare -A ArgMap
  ArgMap['--opt1']='--opt1'
  ArgMap['--opt2']='--opt2'
  ArgMap['--help']='--help'
  ArgMap['-h']='-h'
  OptionsArgsAliasNormalize ' OptionsArgsAliasNormalizeTestDef_help_onealias' 'ArgList' 'ArgMap'
  AssociativeMapAssertKeyValue $LINENO 'ArgMap' '--opt1' '--opt1' '--opt2' '--opt2' '--help' '-h'
  ArrayAssertValues $LINENO 'ArgList' '--opt1' '--opt2' '--help'
  echo "$FUNCNAME Test 6: Successful"

  echo "$FUNCNAME Test 7: Two different options are assigned alias that are specified."
  unset ArgMap
  unset ArgList
  declare -a ArgList
  ArgList+=( '-h' )
  ArgList+=( '--T2' )
  ArgList+=( 'Test Spaces' )
  declare -A ArgMap
  ArgMap['-h']='-h'
  ArgMap['--T2']='--T2'
  OptionsArgsAliasNormalize 'OptionsArgsAliasNormalizeTestDef_help_Twoalias' 'ArgList' 'ArgMap'
  AssociativeMapAssertKeyValue $LINENO 'ArgMap' '--help' '-h' '--Test2' '--T2' 
  ArrayAssertValues $LINENO 'ArgList' '--help' '--Test2' 'Test Spaces'
  echo "$FUNCNAME Test 7: Successful"
}

function  OptionsArgsAliasNormalizeTestDef_Noalias () {
cat <<OPTIONARGS_HELP
--Test single false "" required ""
OPTIONARGS_HELP
return 0
}

function  OptionsArgsAliasNormalizeTestDef_help_onealias () {
cat <<OPTIONARGS_HELP
--help single false "" required "-h"
--Test2 single false "" required ""
OPTIONARGS_HELP
return 0
}

function  OptionsArgsAliasNormalizeTestDef_help_Twoalias () {
cat <<OPTIONARGS_HELP
--help single false "" required -h
--Test2 single false "" required "--T2"
OPTIONARGS_HELP
return 0
}

function  OptionsArgsAliasNormalizeTestDef_help_Compoundalias () {
cat <<OPTIONARGS_HELP
--help single false "" required "-h -help"
--Test2 single false "" required "--T2"
OPTIONARGS_HELP
return 0
}
###############################################################################
##
##  Purpose:
##    Test the routine that verifies the values of option and arguments.
##
##  Outputs:   
##    When Failure: 
##      Identifies test, line numbers and reason for failure.
##
###############################################################################
function OptionsArgsValueVerifyTest () {

  echo "$FUNCNAME Test 1: Two boolean options are assigned 'false' as there values."
  unset ArgMap
  unset ArgList
  declare -a ArgList
  ArgList+=( '--help' )
  ArgList+=( '--bool' )
  declare -A ArgMap
  ArgMap['--help']='false'
  ArgMap['--bool']='false'
  if ! OptionsArgsValueVerify 'OptionsArgsValueVerifyTestDef' 'ArgList' 'ArgMap'; then ScriptUnwind $LINENO "Should have passes this verification."; fi
  AssociativeMapAssertKeyValue $LINENO 'ArgMap' '--help' 'false' '--bool' 'false' 
  ArrayAssertValues $LINENO 'ArgList' '--help' '--bool'
  echo "$FUNCNAME Test 1: Successful."

  echo "$FUNCNAME Test 2: Two boolean options. One assigned 'false' the other 'falses'"
  echo "$FUNCNAME Test 2:   Message and return code should indicate an error."
  unset ArgMap
  unset ArgList
  declare -a ArgList
  ArgList+=( '--help' )
  ArgList+=( '--bool' )
  declare -A ArgMap
  ArgMap['--help']='false'
  ArgMap['--bool']='falses'
  if OptionsArgsValueVerify 'OptionsArgsValueVerifyTestDef' 'ArgList' 'ArgMap'; then ScriptUnwind $LINENO "Should have failed this verification."; fi
  AssociativeMapAssertKeyValue $LINENO 'ArgMap' '--help' 'false' '--bool' 'falses' 
  ArrayAssertValues $LINENO 'ArgList' '--help' '--bool'
  echo "$FUNCNAME Test 2: Successful."
		
  echo "$FUNCNAME Test 3: Callback Parameter not a valid function'"
  echo "$FUNCNAME Test 3:   Message and return code should indicate an error."
  unset ArgMap
  unset ArgList
  declare -a ArgList
  ArgList+=( '--help' )
  ArgList+=( '--bool' )
  declare -A ArgMap
  ArgMap['--help']='false'
  ArgMap['--bool']='falses'
  declare errMsg
  if `errMsg=OptionsArgsValueVerify 'UndefinedCallback' 'ArgList' 'ArgMap'`; then ScriptUnwind $LINENO "Should have failed this verification."; fi
  echo "$errMsg"
  AssociativeMapAssertKeyValue $LINENO 'ArgMap' '--help' 'false' '--bool' 'falses' 
  ArrayAssertValues $LINENO 'ArgList' '--help' '--bool'
  echo "$FUNCNAME Test 3: Successful."

  echo "$FUNCNAME Test 4: Specify an option that hasn't been defined in the definition table.'"
  echo "$FUNCNAME Test 4:   Message and return code should indicate unknown option."
  unset ArgMap
  unset ArgList
  declare -a ArgList
  ArgList+=( '--help' )
  ArgList+=( '--boolx' )
  declare -A ArgMap
  ArgMap['--help']='false'
  ArgMap['--boolx']='falses'
  if OptionsArgsValueVerify 'OptionsArgsValueVerifyTestDef' 'ArgList' 'ArgMap'; then ScriptUnwind $LINENO "Should have failed this verification."; fi
  AssociativeMapAssertKeyValue $LINENO 'ArgMap' '--help' 'false' '--boolx' 'falses' 
  ArrayAssertValues $LINENO 'ArgList' '--help' '--boolx'
  echo "$FUNCNAME Test 4: Successful."

  echo "$FUNCNAME Test 5: Specify an option that hasn't been defined in the definition table.'"
  echo "$FUNCNAME Test 5:   However, add an entry to the definition table to ignore this potential problem."
  unset ArgMap
  unset ArgList
  declare -a ArgList
  ArgList+=( '--help' )
  ArgList+=( '--boolx' )
  declare -A ArgMap
  ArgMap['--help']='false'
  ArgMap['--boolx']='falses'
  if ! OptionsArgsValueVerify 'OptionsArgsValueVerifyTestDef_Ignore' 'ArgList' 'ArgMap'; then ScriptUnwind $LINENO "Should have succeeded this verification."; fi
  AssociativeMapAssertKeyValue $LINENO 'ArgMap' '--help' 'false' '--boolx' 'falses' 
  ArrayAssertValues $LINENO 'ArgList' '--help' '--boolx'
  echo "$FUNCNAME Test 5: Successful."
}
function  OptionsArgsValueVerifyTestDef () {
cat <<OPTIONARGS_HELP
--help single false "OptionsArgsBooleanVerify \\<--help\\>" required ""
--bool single false "OptionsArgsBooleanVerify \\<--bool\\>" required ""
OPTIONARGS_HELP
return 0
}
function  OptionsArgsValueVerifyTestDef_Ignore () {
cat <<OPTIONARGS_HELP
--help single false "OptionsArgsBooleanVerify \\<--help\\>" required ""
--bool single false "OptionsArgsBooleanVerify \\<--bool\\>" required ""
--Ignore-Unknown-OptArgs single --Ignore-Unknown-OptArgs "" optional ""
OPTIONARGS_HELP
return 0
}
###############################################################################
##
##  Purpose:
##    Test the routine that assigns options their default values if they
##    haven't been specified.
##
##  Outputs:   
##    When Failure: 
##      Identifies test, line numbers and reason for failure.
##
###############################################################################
function OptionsArgsRequireVerifyTest () {
  echo "$FUNCNAME Test 1: Define two boolean options. One is assigned a value"
  echo "$FUNCNAME Test 1:   while the other should be assigned its default value."
  unset ArgMap
  unset ArgList
  declare -a ArgList
  ArgList+=( '--bool' )
  ArgList+=( '--help' )
  declare -A ArgMap
  ArgMap['--help']='false'
  if ! OptionsArgsRequireVerify 'OptionsArgsRequireVerifyTesttDef' 'ArgList' 'ArgMap'; then ScriptUnwind $LINENO "Should have passed this verification."; fi
  AssociativeMapAssertKeyValue $LINENO 'ArgMap'  '--bool' 'true' '--help' 'false' 
  ArrayAssertValues $LINENO 'ArgList' '--bool' '--help'
  echo "$FUNCNAME Test 1: Successful."

  echo "$FUNCNAME Test 2: Do not define any options on the 'command line'"
  echo "$FUNCNAME Test 2:   however, two options defined in the table should"
  echo "$FUNCNAME Test 2:   be added in the order they appear in the table and"
  echo "$FUNCNAME Test 2:   both should be assigned their default values."
  unset ArgMap
  unset ArgList
  declare -a ArgList
  declare -A ArgMap
  if ! OptionsArgsRequireVerify 'OptionsArgsRequireVerifyTesttDef' 'ArgList' 'ArgMap'; then ScriptUnwind $LINENO "Should have passed this verification."; fi
  AssociativeMapAssertKeyValue $LINENO 'ArgMap' '--help' 'false' '--bool' 'true'
  ArrayAssertValues $LINENO 'ArgList' '--help' '--bool'
  echo "$FUNCNAME Test 2: Successful."

  echo "$FUNCNAME Test 3: Do define one option on the 'command line' that needs to be ignored"
  echo "$FUNCNAME Test 3:   however, the other two options defined in the table should"
  echo "$FUNCNAME Test 3:   be added in the order they appear in the table and"
  echo "$FUNCNAME Test 3:   both should be assigned their default values."
  unset ArgMap
  unset ArgList
  declare -a ArgList
  declare -A ArgMap
  if ! OptionsArgsRequireVerify 'OptionsArgsRequireVerifyTestDef_Ignore' 'ArgList' 'ArgMap'; then ScriptUnwind $LINENO "Should have passed this verification."; fi
  AssociativeMapAssertKeyValue $LINENO 'ArgMap' '--help' 'true' '--bool' 'true'
  ArrayAssertValuesAll $LINENO 'ArgList' '--help' '--bool'
  echo "$FUNCNAME Test 3: Successful."

  echo "$FUNCNAME Test 4: An optional option was specified without its value."
  echo "$FUNCNAME Test 4:   Should assume default value from the table."
  unset ArgMap
  unset ArgList
  declare -a ArgList
  ArgList+=( '--bool' )
  declare -A ArgMap
  ArgMap['--bool']=''
  if ! OptionsArgsRequireVerify ' OptionsArgsRequireVerifyTesttDef_optional' 'ArgList' 'ArgMap'; then ScriptUnwind $LINENO "Should have passed this verification."; fi
  AssociativeMapAssertKeyValue $LINENO 'ArgMap' '--help' 'false' '--bool' 'true'
  ArrayAssertValuesAll $LINENO 'ArgList' '--bool' '--help'
  echo "$FUNCNAME Test 4: Successful."

  echo "$FUNCNAME Test 5: Table definition has invalid 'presence' column value."
  echo "$FUNCNAME Test 5:   Should generate error message with appropriate return code value."
  unset ArgMap
  unset ArgList
  declare -a ArgList
  declare -A ArgMap
  declare errMsg
  if errMsg="`OptionsArgsRequireVerify 'OptionsArgsRequireVerifyTesttDef_InvalidPresence' 'ArgList' 'ArgMap'`"; then ScriptUnwind $LINENO "Should have failed this verification."; fi
  echo $errMsg
  ArrayMapAssertElementCount $LINENO 'ArgMap' 0
  ArrayMapAssertElementCount $LINENO 'ArgList' 0
  echo "$FUNCNAME Test 5: Successful."
}
function  OptionsArgsRequireVerifyTesttDef () {
cat <<OPTIONARGS_HELP
--help single false "OptionsArgsBooleanVerify \\<--help\\>" required ""
--bool single true "OptionsArgsBooleanVerify \\<--bool\\>" required ""
OPTIONARGS_HELP
return 0
}
function  OptionsArgsRequireVerifyTestDef_Ignore () {
cat <<OPTIONARGS_HELP
--help single true "OptionsArgsBooleanVerify \\<--help\\>" required ""
--bool single true "OptionsArgsBooleanVerify \\<--bool\\>" required ""
--Ignore-Unknown-OptArgs single --Ignore-Unknown-OptArgs "" optional ""
OPTIONARGS_HELP
return 0
}
function  OptionsArgsRequireVerifyTesttDef_optional() {
cat <<OPTIONARGS_HELP
--help single false "OptionsArgsBooleanVerify \\<--help\\>" required ""
--bool single true "OptionsArgsBooleanVerify \\<--bool\\>" optional ""
OPTIONARGS_HELP
return 0
}
function  OptionsArgsRequireVerifyTesttDef_InvalidPresence() {
cat <<OPTIONARGS_HELP
--help single false "OptionsArgsBooleanVerify \\<--help\\>" rquired ""
--bool single true "OptionsArgsBooleanVerify \\<--bool\\>" optonal ""
OPTIONARGS_HELP
return 0
}
###############################################################################
##
##  Purpose:
##    Test the routine that creates a new set of option/argument list and 
##    map arrays by applying a filter expression to a set of existing ones.
##
##  Outputs:   
##    When Failure: 
##      Identifies test, line numbers and reason for failure.
##
###############################################################################
function OptionsArgsFilterTest () {
  echo "$FUNCNAME Test 1: Include only the arguments in the resulting arrays." 
  echo "$FUNCNAME Test 1:   that match the pattern: 'Arg[0-9][0-9]*'"
  unset ArgList
  unset ArgMap
  unset ArgListNew
  unset ArgMapNew
  declare -a ArgList
  ArgList+=( '--bool' )
  ArgList+=( 'Arg1' )
  ArgList+=( 'Arg2' )
  ArgList+=( 'Arg3' )
  declare -A ArgMap
  ArgMap['--bool']='true'
  ArgMap['Arg1']='Arg1'
  ArgMap['Arg2']='Arg21'
  ArgMap['Arg3']='Arg3'
  declare -a ArgListNew
  declare -A ArgMapNew
  OptionsArgsFilter ArgList ArgMap ArgListNew ArgMapNew '[[ "$optArg" =~ Arg[0-9][0-9]* ]]' 'true'
  ArrayAssertValuesAll $LINENO 'ArgListNew' 'Arg1' 'Arg2' 'Arg3'
  AssociativeMapAssertKeyValue $LINENO 'ArgMapNew' 'Arg1' 'Arg1' 'Arg2' 'Arg21' 'Arg3' 'Arg3'
  echo "$FUNCNAME Test 1: Successful."

  echo "$FUNCNAME Test 2: Include only options that aren't dlw ones in the resulting arrays."
  unset ArgList
  unset ArgMap
  unset ArgListNew
  unset ArgMapNew
  declare -a ArgList
  ArgList+=( '-i' )
  ArgList+=( '-t' )
  ArgList+=( '--dlwdepnd' )
  ArgList+=( '--no-cache' )
  ArgList+=( '--dlwforce' )
  ArgList+=( 'Arg1' )
  ArgList+=( 'Arg2' )
  ArgList+=( 'Arg3' )
  declare -A ArgMap
  ArgMap['--dlwdepnd']='true'
  ArgMap['--no-cache']='true'
  ArgMap['-t']='5'
  ArgMap['Arg1']='Arg1'
  ArgMap['Arg2']='Arg21'
  ArgMap['Arg3']='Arg3'
  declare -a ArgListNew
  declare -A ArgMapNew
  OptionsArgsFilter ArgList ArgMap ArgListNew ArgMapNew '( [[ "$optArg"  =~ ^-[^-].*$ ]] || [[ "$optArg"  =~ ^--.*$ ]] ) && ! [[ "$optArg"  =~ ^--dlw.*$ ]]' 'true'
  ArrayAssertValuesAll $LINENO 'ArgListNew' '-i' '-t' '--no-cache'
  AssociativeMapAssertKeyValue $LINENO 'ArgMapNew' '-i' '' '-t' '5' '--no-cache' 'true'
  echo "$FUNCNAME Test 2: Successful."
}
###############################################################################
##
##  Purpose:
##    Unit test functions defined in the ArgumentsGetInclude.sh.
##
###############################################################################
function main (){
  if ! ArgumentsParseTest;            then ScriptUnwind $LINENO "Unexpected return code: '$?', should be '0'"; fi
  if ! OptionsArgsAliasNormalizeTest; then ScriptUnwind $LINENO "Unexpected return code: '$?', should be '0'"; fi
  if ! OptionsArgsRequireVerifyTest;  then ScriptUnwind $LINENO "Unexpected return code: '$?', should be '0'"; fi
  if ! OptionsArgsValueVerifyTest;    then ScriptUnwind $LINENO "Unexpected return code: '$?', should be '0'"; fi
  if ! OptionsArgsFilterTest;         then ScriptUnwind $LINENO "Unexpected return code: '$?', should be '0'"; fi
}
FunctionOverrideIncludeGet
main
exit 0;
