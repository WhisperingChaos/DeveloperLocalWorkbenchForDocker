#!/bin/bash
##############################################################################
##
##  Purpose:
##    Package up all the command line arguments into an array.  Must be done
##    at initial calling level within script to properly preserve
##    quotes within option/argument values.
##
##  Inputs:
##    $1-$N arguments passed to the body of the main function.
##
###############################################################################
declare a mainArgumentList
while [ $# -ne 0 ]; do
  mainArgumentList+=("$1")
  shift
done
#  call the main function that should be defined in every command script file 
main 'mainArgumentList'
