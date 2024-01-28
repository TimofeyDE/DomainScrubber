#!/bin/bash

# Debugging
#set -x n

#################### FUNCTION ####################
# Function to print usage
usage() {
    echo "Usage: $0 -f <file_path.csv> -d <database_name> -e <db_entity> [-c <config_file.cnf>]"
    exit 1
}

# Function to escape SQL strings
sql_escape() {
    sed "s/'/''/g"
}

# Function to update database records
update_record() {
    local ID="$1"
    local VALUE="$2"
    local DOMAIN="$3"

    # Remove DOMAIN from news_content and escape for SQL
    local NEW_VALUE=$(echo "$VALUE" | sed -E "s# href=['\"]https?://www\.$DOMAIN['\"]##gi" | sql_escape)

    # Construct and execute the update query
    local UPDATE_SQL="UPDATE $DB_ENTITY SET NewsContent = '$NEW_VALUE' WHERE id LIKE $ID;"

    if mysql --defaults-extra-file="$CONF" "$DB_NAME" -e "$UPDATE_SQL"; 
    then
        return 0
    else
        return 1
    fi
}

# Function to process each domain
process_domain() {
    local DOMAIN="$1"
    local EXTRACT_SQL="SELECT id, NewsContent FROM $DB_ENTITY WHERE NewsContent LIKE '%$DOMAIN%'"
    local QUERY="SELECT id, NewsContent, COUNT(*) OVER() AS total_count FROM $DB_ENTITY WHERE NewsContent LIKE '%$DOMAIN%'"

    # Counters
    local UPDATE_COUNT=0
    local COUNT=0

    while IFS=$'\t' read -r ID VALUE TOTAL; 
    do
        COUNT="$TOTAL"

        [ -z "$ID" ] || [ "$ID" = "ID" ] && continue

        if update_record "$ID" "$VALUE" "$DOMAIN"; 
        then
            ((UPDATE_COUNT++))
        else
            echo -ne "${RED}The record was not updated${CLEAR}"
        fi
    done < <(mysql --defaults-extra-file="$CONF" "$DB_NAME" -e "$EXTRACT_SQL" | sed '1d')

    if [[ "$COUNT" -ne 0 && "$UPDATE_COUNT" -eq "$COUNT" ]];
    then
        echo -e "${BOLD}${UPDATE_COUNT}${CLEAR} records for domain ${BOLD}\"${DOMAIN}\"${CLEAR} updated successfully."
    else
        if [ "$UPDATE_COUNT" -eq 0 ];
        then
            echo -e "Records for domain ${BOLD}\"${DOMAIN}\"${CLEAR} were not found!"
        else
            echo -e "Some records for domain ${BOLD}\"${DOMAIN}\"${CLEAR} may not have been updated."
        fi
    fi
}

#################### FORMATING ####################
CLEAR="\033[0m"

# Text settings.
BOLD="\033[1m"
RED="\033[1;31m"
GREEN="\033[1;32m"

#################### VARIABLES ####################
# Database credentials: to specify a filepath to the config file
CONF=

# Enter the path to your CSV file
FILE_PATH=

# Database name
DB_NAME=

# Enter the name of attribute 
DB_ENTITY=

# To save up domains that were processed
declare -A PROCESSED_DOMAINS

# Parse command-line arguments
while getopts ":f:d:e:c:" opt; 
do
    case ${opt} in
        f )
            FILE_PATH=$OPTARG
            ;;
        d )
            DB_NAME=$OPTARG
            ;;
        e )
            DB_ENTITY=$OPTARG
            ;;
        c )
            CONF=$OPTARG
            ;;
        \? )
        echo "Invalid Option: -$OPTARG" 1>&2 usage
        ;;
        : )
        echo "Invalid Option: -$OPTARG requires an argument" 1>&2 usag
        ;;
    esac
done

shift $((OPTIND -1))

# Validate required arguments
if [[ -z "$FILE_PATH" || -z "$DB_NAME" || -z "$DB_ENTITY" ]];
then
    usage
fi

# Validate CSV file
if ! [[ "$FILE_PATH" =~ \.csv$ ]];
then
    echo "Input file must be a CSV file." 
    exit 1
fi

# Validate config file if specified
if [[ -n "$CONF" && ! "$CONF" =~ \.cnf$ ]];
then
    echo "The config file must have a .cnf extension."
    exit 1
fi

#################### CORE LOGIC ####################

# Main loop to iterate over each line from the input file
while IFS= read -r LINE; do
    DOMAIN="$(echo "$LINE" | awk -F, '{print $1}')"

    if [[ -n "$DOMAIN" && -z "${PROCESSED_DOMAINS["$DOMAIN"]}" ]]; then
        PROCESSED_DOMAINS["$DOMAIN"]=1
        process_domain "$DOMAIN"
    fi
done < "$FILE_PATH"

#################### END ####################

