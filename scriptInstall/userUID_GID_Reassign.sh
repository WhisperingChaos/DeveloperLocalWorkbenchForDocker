#!/bin/bash
###############################################################################
#
#  Purpose: 
#    Adapt a container account's UID and GID list so it matches/extends the
#    ones assigned to an external account provided when the container was
#    initially created (docker create/run).  This allows a container account
#    to present the identity associated to the external one so it can assume
#    the same read and write permissions to the host directories/files exposed
#    to the container via docker volume mount (-v).  Avoids having to manually
#    set host ACL lists to permit container account to access host
#    file/directories.
#
#  Inputs:
#    1. $1 - Static container username whose UID/GID list will be adapted
#          to assume the external account's permissions.
#    1. $2 - UID of external account.
#    2. $3 - GID list for external account.
#    
###############################################################################
function main () {
  declare -r user_name="$1"
  declare -r UID_new="$2"
  declare -r GID_list="$3"
  if [ -n "$UID_new" ]; then
    UIDadapt "$user_name" "$UID_new"
  fi
  if [ -n "$GID_list" ]; then
    GIDadapt "$user_name" "$GID_list"
  fi
}
###############################################################################
#
#  Purpose: 
#    Adapt the statically defined container account to reflect the
#    UID specified when creating the container from its image.  This will 
#    currently permit processes running within the container to mimic the
#    UID specified when the container was created from its image.  This allows
#    processes within the container to access the same set of files, via owner
#    permissions, for the provided UID.
#
#  Assumes:
#    > If it is called more than once, all calls must provide same external
#      account UID, otherwise, the container's primary GID will most likely
#      be 'forgotten', preventing access to the container's account's
#      files created when generating the image.
#
#  Inputs:
#    1.  $1 - The textual linux account name defined within the container
#           that will assume the UID of the external account. 
#    2.  $2 - The UID of the external account specified during docker create/run.
#    
###############################################################################
function UIDadapt () {
  declare -r user_name="$1"
  declare -r UID_new="$2"

  declare -r UID_original="`id -u "$user_name"`"
  if [ "$UID_original" == "$UID_new" ]; then
    # Existing container UID identical to the one we want to assume
    # :: existing UNIX ACLs do not require adjustment.
    return 0
  fi
  # Must adapt container account UID to honor its current group ACLs,
  # and change its UID so it assumes the same identity as the privided UID
  if ! usermod -u $UID_new "$user_name"; then Abort $LINENO "Failed to update container UID from: '$UID_original' to: '$UID_new' for user: '$user_name'"; fi
}
###############################################################################
#
#  Purpose: 
#    Adapt the statically defined container account to assume an extended GID
#    set including the initial container account GIDs and GIDs specified
#    for the eternal account.  The set union operator implements extending
#    the container account's GID set, so processes started
#    by the container account within the container can continue to
#    access resources created during image generation, and when these container
#    processes attempt to access external resources made available to
#    the container, that they will be able to do so.
#
#  Assumes:
#    > Since the GID's betweeen the container and enternal environment aren't
#      correlated and this function generates a composite GID set for 
#      the account running in the container, this composite set will
#      potentially broaden access to resources both within the container
#      and those external to the container that was potentially restricted.
#
#  Inputs:
#    1.  $1 - The textual linux account name defined within the container
#           that will assume the UID of the external account. 
#    2.  $2 - The list of GIDs associated to the external account
#           specified during docker create/run.
#    
###############################################################################
function GIDadapt () {
  declare user_name="$1"
  declare GID_list="$2"
  declare -A GID_map

  declare GID
  for GID in $GID_list
  do
    GID_map[$GID]="$GID"
    # this external GID may or may not be in container /etc/groups,
    # add it and ignore overlaps.
    groupadd --gid $GID "$GID" >/dev/null 2>/dev/null
  done
  # include the already associated container GIDs in the combined set
  # and mark them as such.
  declare GID_name
  declare scan='true'
  for GID_name in $( groups "$user_name" )
  do
    if $scan; then
      if [ "$GID_name" == ':' ]; then scan='false'; fi
      continue
    fi
    GID="`getent group "$GID_name" | cut -d: -f3`"
    if [ -z "$GID" ]; then Abort "$LINENO" "Failed to generate GID for group name: '$GID_name' associated to: '$user_name'."; fi
    GID_map[$GID]='ASSOCIATED'
  done
  # iterate over GIDs and add them to the container's account GID list if they haven't aleady been associated.
  declare key
  for key in "${!GID_map[@]}"
  do
    GID_name="${GID_map[$key]}"
    if [ "$GID_name" != 'ASSOCIATED' ]; then
      if ! usermod -a -G "$GID_name" "$user_name"; then Abort "$LINENO" "Adding external GID: '$key' to container account: '$user_name' failed."; fi
    fi
  done
  return 0
}
###############################################################################
#
#  Purpose: 
#    Terminate this process writing abort message to STDERR.
#
#  Inputs:
#    1.  $1 - Line number.
#    2.  $2 - Abort message.
#    
###############################################################################
function Abort (){
  echo "Abort: '$0', LineNo: '$1', Message: $2" >&2 
  exit 1
}
###############################################################################
main "$@"
