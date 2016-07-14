#!/bin/bash -e
###############################################################################
#    __  __        _____           _   _
#   |  \/  |      / ____|         | | (_)            TM
#   | \  / |_   _| |  __ _ __ __ _| |_ _  ___  _ __
#   | |\/| | | | | | |_ | '__/ _` | __| |/ _ \| '_ \
#   | |  | | |_| | |__| | | | (_| | |_| | (_) | | | |
#   |_|  |_|\__, |\_____|_|  \__,_|\__|_|\___/|_| |_|
#            __/ |
#           |___/
#
#
#   Copyright 2016 William Ashworth
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.


set -e              # exit on command errors (failsafe; so you MUST handle exit codes properly!)
set -E              # pass trap handlers down to subshells
set -o pipefail     # capture fail exit codes in piped commands
#set -x             # execution tracing debug messages

# Other variables
[ "$NOW" ]             ||  NOW=$(date +"%Y%m%d-%H%M%S")
[ "$SOURCE" ]          ||  SOURCE=

# Evaluate the backup directory path to ensure it's not using tilde (~)
# We really want full paths to be safer
if [[ "$BACKUP_DIR" ]]
then
    BACKUP_EVAL=`eval echo ${BACKUP_DIR//>}`
    BACKUP_DIR=$BACKUP_EVAL
fi

# Error handler
on_err() {
	echo ">> ERROR: $?"
	FN=0
	for LN in "${BASH_LINENO[@]}"; do
		[ "${FUNCNAME[$FN]}" = "main" ] && break
		echo ">> ${BASH_SOURCE[$FN]} $LN ${FUNCNAME[$FN]}"
		FN=$(( FN + 1 ))
	done
}
trap on_err ERR

# Exit handler
declare -a EXIT_CMDS
add_exit_cmd() { EXIT_CMDS+="$*;  "; }
on_exit(){ eval "${EXIT_CMDS[@]}"; }
trap on_exit EXIT

# Detect paths
MYSQL=$(which mysql)
MYSQL_CONFIG_EDITOR=$(which mysql_config_editor)
MYSQLDUMP=$(which mysqldump)
AWK=$(which awk)
GREP=$(which grep)

# Get command info
CMD_PWD=$(pwd)
CMD="$0"
CMD_DIR="$(cd "$(dirname "$CMD")" && pwd -P)"

# Defaults and command line options
[ "$VERBOSE" ] ||  VERBOSE=
[ "$DEBUG" ]   ||  DEBUG=

# Basic helpers
out() { echo "$(date +%Y%m%dT%H%M%SZ): $*"; }
err() { out "$*" 1>&2; }
vrb() { [ ! "$VERBOSE" ] || out "$@"; }
dbg() { [ ! "$DEBUG" ] || err "$@"; }
die() { err "EXIT: $1" && [ "$2" ] && [ "$2" -ge 0 ] && exit "$2" || exit 1; }

# Show help function to be used below
show_help() {
	awk 'NR>1{print} /^(###|$)/{exit}' "$CMD"
	echo "USAGE: $(basename "$CMD") [arguments]"
	echo "ARGS:"
	MSG=$(awk '/^NARGS=-1; while/,/^esac; done/' "$CMD" | sed -e 's/^[[:space:]]*/  /' -e 's/|/, /' -e 's/)//' | grep '^  -')
	EMSG=$(eval "echo \"$MSG\"")
	echo "$EMSG"
}

# Parse command line options (odd formatting to simplify show_help() above)
NARGS=-1; while [ "$#" -ne "$NARGS" ]; do NARGS=$#; case $1 in

	# SWITCHES
	-h|--help)                 # This help message
		show_help; exit 1; ;;
	-d|--debug)                # Enable debugging messages (implies verbose)
		DEBUG=$(( DEBUG + 1 )) && VERBOSE="$DEBUG" && shift && echo "#-INFO: DEBUG=$DEBUG (implies VERBOSE=$VERBOSE)"; ;;
	-v|--verbose)              # Enable verbose messages
		VERBOSE=$(( VERBOSE + 1 )) && shift && echo "#-INFO: VERBOSE=$VERBOSE"; ;;

    # CONFIGURATION
    -c|--config)               # Override to pass a custom config file if desired
        shift && CONFIG="$1" && shift && vrb "#-INFO: CONFIG=$CONFIG"; ;;

	# PAIRS
    -s|--source)               # The starting point for our data. Where we're copying from. Options are currently 'remote' or 'local'
        shift && SOURCE="$1" && shift && vrb "#-INFO: SOURCE=$SOURCE"; ;;
    -b|--backupdir)            # Backup directory
        shift && BACKUP_DIR="$1" && shift && vrb "#-INFO: BACKUP_DIR=$BACKUP_DIR"; ;;

    # Remote Database Options
    -rhost|--remotehost)       # Remote database username
        shift && REMOTE_HOST="$1" && shift && vrb "#-INFO: REMOTE_HOST=$REMOTE_HOST"; ;;
    -rport|--remoteport)       # Remote database username
        shift && REMOTE_PORT="$1" && shift && vrb "#-INFO: REMOTE_PORT=$REMOTE_PORT"; ;;
    -ruser|--remoteuser)       # Remote database username
        shift && REMOTE_USER="$1" && shift && vrb "#-INFO: REMOTE_USER=$REMOTE_USER"; ;;
    -rpass|--remotepass)       # Remote database username
        shift && REMOTE_PASS="$1" && shift && vrb "#-INFO: REMOTE_PASS=$REMOTE_PASS"; ;;
    -rdb|--remotedb)           # Remote database name
        shift && REMOTE_DB="$1" && shift && vrb "#-INFO: REMOTE_DB=$REMOTE_DB"; ;;

    # Local Database Options
    -lhost|--localhost)        # Local database username
        shift && LOCAL_HOST="$1" && shift && vrb "#-INFO: LOCAL_HOST=$LOCAL_HOST"; ;;
    -lport|--localport)        # Local database username
        shift && LOCAL_PORT="$1" && shift && vrb "#-INFO: LOCAL_PORT=$LOCAL_PORT"; ;;
    -luser|--localuser)        # Local database username
        shift && LOCAL_USER="$1" && shift && vrb "#-INFO: LOCAL_USER=$LOCAL_USER"; ;;
    -lpass|--localpass)        # Local database username
        shift && LOCAL_PASS="$1" && shift && vrb "#-INFO: LOCAL_PASS=$LOCAL_PASS"; ;;
    -ldb|--localdb)            # Local database name
        shift && LOCAL_DB="$1" && shift && vrb "#-INFO: LOCAL_DB=$LOCAL_DB"; ;;

	*)
		break;
esac; done

[ "$DEBUG" ]  &&  set -x

###############################################################################

# Failsafes
[ $# -eq 0 ]  ||  die "ERROR: Unexpected arguments!

    ./$(basename $CMD) [arguments] or
    ./$(basename $CMD) -h"

# See if we have a custom/passed value
# If not, assume default location
if [ -z "$CONFIG" ]; then
    CONFIG="~/.mygration-config"
fi

# Check for a config file and load it
if [ -f ~/.mygration-config ]; then
	. ~/.mygration-config
else
    die "This script is expecting a config file located at ~/.mygration-config. Please ensure you have one and that permissions are correct."
fi

# Validate a few items
[ $# -gt 0 -a -z "$SOURCE" ]  &&  SOURCE="$1"  &&  shift
[ "$SOURCE" ]  ||  die "What's the source (or starting point) of your data? ie., where are we starting our migration from?"

    if ! [[ $SOURCE == "remote" || $SOURCE == "local" ]]; then
        die "It doesn't look like you've entered a valid source. Please try 'remote' or 'local'."
    fi

[ $# -gt 0 -a -z "$REMOTE_DB" ]  &&  REMOTE_DB="$1"  &&  shift
[ "$REMOTE_DB" ]  ||  die "You must tell us which remote database name you want to interact with."

[ $# -gt 0 -a -z "$LOCAL_DB" ]  &&  LOCAL_DB="$1"  &&  shift
[ "$LOCAL_DB" ]  ||  die "You must tell us which local database name you want to interact with."


# Verify we have a backup directory, and that we're able to write to it
# If we don't, ask if we can create it with user's consent
mkdir_backup_path() {
    echo "ERROR: Directory $BACKUP_DIR does not exist. Unfortunately for safety reasons, it's a requirement."

    while true; do
        read -p "Would you like me to create it for you? " yn
        case $yn in
            [Yy]* ) mkdir -p "`eval echo ${BACKUP_DIR//>}`"; break;;
            [Nn]* ) exit;;
            * ) echo "Please answer yes or no.";;
        esac
    done

    # Confirm until we know we're golden
    [[ -d "${BACKUP_DIR}" ]]  ||  mkdir_backup_path
}
if [[ ! -d "`eval echo ${BACKUP_DIR//>}`" ]]; then
    mkdir_backup_path
fi

###############################################################################

# ----------------------------------------
# ./mysqlsync source source_db destination_db other_options
# ----------------------------------------

# Setting up login creds for MySQL
create_mysql_credentials() {
    local HOST=$1
    local USER=$2
    local PASS=$3
    local PORT=$4

    out "We couldn't determine a saved MySQL profile for '$HOST'. We're setting that up for you, but it requires a password to be typed. Please note that you'll only have to do this once for '$HOST'; unless/until the password for that MySQL server is eventually changed."
    out ""
    out "When prompted, please provide the following password:"
    out "$PASS"

    $MYSQL_CONFIG_EDITOR set --login-path=$HOST --host=$HOST --port=$PORT --user=$USER --password
}
remove_mysql_credentials() {
    local HOST=$1
    $MYSQL_CONFIG_EDITOR remove --login-path=$HOST
}
verify_mysql_credentials() {
    local HOST=$1
    local USER=$2
    local PASS=$3
    local PORT=$4

    # remove credentials when debugging
    # remove_mysql_credentials $HOST
    # mysql_config_editor print --login-path=$HOST

    MYSQL_CONFIG_EXISTS=$(mysql_config_editor print --login-path=$HOST | grep "$HOST" > /dev/null; echo "$?")
    if [ "$MYSQL_CONFIG_EXISTS" -eq 0 ]; then
        # vrb mysql_config_editor print --login-path=$HOST
        vrb "Awesome! We found a saved configuration for '$HOST'. Proceeding."
    else
        vrb "We need to create secure access to MySQL. This will only take a moment."
        create_mysql_credentials $HOST $USER $PASS $PORT
        vrb "Sweet. We're all good with access to '$HOST'. Proceeding."

        # test again for safe measure
        verify_mysql_credentials

        vrb "Everything confirmed and verified. Proceeding."
    fi

    # report on the newest, freshest info
    vrb mysql_config_editor print --login-path=$HOST
}

# -----------------------------------------------------------------------

# Verify some permissions with MySQL
vrb "We need to setup some access information for MySQL to work as expected."
verify_mysql_credentials $REMOTE_HOST $REMOTE_USER $REMOTE_PASS $REMOTE_PORT
verify_mysql_credentials $LOCAL_HOST $LOCAL_USER $LOCAL_PASS $LOCAL_PORT
vrb "Both MySQL accesses have been verified. Proceeding."

# -----------------------------------------------------------------------

# Example of flushing/removing saved login credentials for MySQL
# (future feature for CLI)
# remove_mysql_credentials $REMOTE_HOST

# -----------------------------------------------------------------------


verify_database_exists() {
    local HOST=$1
    local PORT=$2
    local DATABASE=$3

    vrb $HOST




    # ----------------------------------------

    # REMOTE_EXISTS=$(mysql --login-path=$HOST --batch --skip-column-names -e "SHOW DATABASES LIKE \"$DATABASE\";" | grep "$DATABASE")

    # if [[ $? != 0 ]]; then
    #     die "first"
    #     die "Checking for $DATABASE failed. Please report this error."
    # elif [[ $REMOTE_EXISTS ]]; then
    #     die "REMOTE EXISTS"
    #     vrb "The database '$DATABASE' has been found to exist on '$HOST'. Proceeding."
    # else
    #     die "else"
    #     die "Oops! We couldn't find '$DATABASE' on the '$HOST' server. Are you sure it's there?"
    # fi
    # die "end of conditional checks"

    # ----------------------------------------




    $MYSQL --login-path=$HOST --port=$PORT --batch --skip-column-names -e "SHOW DATABASES LIKE '"$DATABASE"';" > /tmp/$HOST_$DATABASE

    if [[ $? != 0 ]]; then
        die "Checking for $DATABASE failed. Please report this error."
    elif grep -q "Can't connect to MySQL server" /tmp/$HOST_$DATABASE; then
        die "error!!!"
    elif grep -q "$DATABASE" /tmp/$HOST_$DATABASE; then
        vrb "The database '$DATABASE' has been found to exist on '$HOST'. Proceeding."
    else
        out "Oops! We couldn't find '$DATABASE' on the '$HOST' server."
        while true; do
            read -p "Would you like me to create it for you? Answering 'no' will exit this program. " yn

            case $yn in

                [Yy]* )
                    out "Thank you. Creating $DATABASE";
                    create_database $HOST $PORT $DATABASE;
                    break;;

                [Nn]* )
                    die "Unfortunately, we cannot proceed without a database. Exiting.";
                    exit;;

                * ) echo "Please answer yes or no.";;
            esac
        done

        # confirm it's good
        verify_database_exists $HOST $PORT $DATABASE
    fi
}
create_database() {
    local HOST=$1
    local PORT=$2
    local DATABASE=$3

    $MYSQL --login-path=$HOST --port=$PORT -e "CREATE DATABASE $DATABASE;"
    vrb "'$DATABASE' has been successfully created on '$host'. Proceeding."
}
empty_database() {
    local HOST=$1
    local PORT=$2
    local DATABASE=$3

    die "Coming soon..."
}
backup_database() {
    local HOST=$1
    local PORT=$2
    local DATABASE=$3

    vrb "Starting backup of '$DATABASE' on '$HOST'"
    $MYSQLDUMP --login-path=$HOST --port=$PORT $DATABASE > "$BACKUP_DIR/${HOST}__${DATABASE}__${NOW}.sql";
    vrb "Completed backup of '$DATABASE' on '$HOST'"
}
migrate_prechecks() {
    # Confirm both databases exist
    verify_database_exists $REMOTE_HOST $REMOTE_PORT $REMOTE_DB
    verify_database_exists $LOCAL_HOST $LOCAL_PORT $LOCAL_DB

    # Backup both databases just in case
    backup_database $REMOTE_HOST $REMOTE_PORT $REMOTE_DB
    backup_database $LOCAL_HOST $LOCAL_PORT $LOCAL_DB
}


# Migrate remote to local mysql server
migrate_remote_to_local() {
    # local HOST=$1
    # local PORT=$2
    # local DATABASE=$3

    migrate_prechecks
    die "END OF SCRIPT"
}

# Migrate local to remote mysql server
migrate_local_to_remote() {
    echo "something"
}

if [[ $SOURCE == "remote" ]]; then
    migrate_remote_to_local ###########
else
    echo "migrate_local_to_remote"
fi

exit;
