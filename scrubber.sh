#!/bin/bash

# Debugging
#set -x n

#################### FORMATING ####################
CLEAR="\033[0m"

# Text settings.
BOLD="\033[1m"
RED="\033[1;31m"
GREEN="\033[1;32m"

#################### VARIABLES ####################
# Database credentials: to specify a filepath to the config file
CONF="config.cnf"

# Database name
DB_NAME="dbemage"

# Enter the name of attribute 
DB_ENTITY="Emage_News"

# Enter the path to your CSV file
FILE_PATH="brokenDomain.csv"

# To save up domains that were processed
declare -A PROCESSED_DOMAINS

#################### FUNCTION ####################
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
    local NEW_VALUE=$(echo "$VALUE" | sed -E "s#href=['\"]https?://www\.$DOMAIN['\"]##gi" |sql_escape)

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
        fi
    done < <(mysql --defaults-extra-file="$CONF" "$DB_NAME" -e "$EXTRACT_SQL" | sed '1d')

    if [[ -z "$COUNT" && "$UPDATE_COUNT" -eq "$COUNT" ]];
    then
        echo -e "${BOLD}${UPDATE_COUNT}${CLEAR} records of the domain ${BOLD}\"${DOMAIN}\"${CLEAR} updated successfully."
    else
        if [ "$UPDATE_COUNT" -eq 0 ];
        then
            echo -e "Records for domain ${BOLD}\"${DOMAIN}\"${CLEAR} were not found!"
        else
            echo -e "Some records ${BOLD}\"${UPDATE_COUNT}\"${CLEAR} may not have been updated."
        fi
    fi
}

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

