#!/bin/bash
# ---------------------------------------------------------------------------
# orgleaks.sh - To run gitleaks for an organization

# Copyright 2021, Rajan Christian
  
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License at <http://www.gnu.org/licenses/> for
# more details.

# Usage: orgleaks.sh [-h|--help] [-o|--org github] [-v] [-a|--gitleaks-args "--report=org-gitleaks-result --format=csv"]

# Revision history:
# 2021-01-21 Initial commit
# 2021-02-09 Ability to download from github pages and save report
# ---------------------------------------------------------------------------

PROGNAME="orgleaks.sh"
VERSION="0.1"

clean_up() { # Perform pre-exit housekeeping
  return
}

error_exit() {
  echo -e "${PROGNAME}: ${1:-"Unknown Error"}" >&2
  clean_up
  exit 1
}

graceful_exit() {
  clean_up
  exit
}

signal_exit() { # Handle trapped signals
  case $1 in
    INT)
      error_exit "Program interrupted by user" ;;
    TERM)
      echo -e "\n$PROGNAME: Program terminated" >&2
      graceful_exit ;;
    *)
      error_exit "$PROGNAME: Terminating on unknown signal" ;;
  esac
}

usage() {
  echo -e "Usage: $PROGNAME [-h|--help] [-o|--org github] [-v] [-a|--gitleaks-args]"
}

help_message() {
  cat <<- _EOF_
                         .__                 __             
     ___________  ____   |  |   ____ _____  |  | __  ______ 
    /  _ \_  __ \/ ___\  |  | _/ __ \\__  \ |  |/ / /  ___/ 
   (  <_> )  | \/ /_/  > |  |_\  ___/ / __ \|    <  \___ \  
    \____/|__|  \___  /  |____/\___  >____  /__|_ \/____  > 
               /_____/             \/     \/     \/     \/  
  

  $PROGNAME ver. $VERSION
  To run gitleaks for an organization

  $(usage)

  Options:
  -h, --help  Display this help message and exit.
  -o, --org github  Organization Name
      where 'github' is the Organization Name.
  -s, --save-file orgleaks_report_github
      where 'orgleaks_report_github' is the Report Name.
  -f, --format csv
      where 'csv' is the Report Format.
  -v  verbose
  -a, --gitleaks-args "--config-path=gitleaks.toml"
      where '"--config-path=gitleaks.toml"' are the arguments for Gitleaks
      refer to https://github.com/zricethezav/gitleaks/wiki/Scanning

  Examples:

  orgleaks.sh -o github
  Scans the 'github' organization

  orgleaks.sh -o github -v 
  Scans the 'github' organization and enables verbosity for gitleaks

  orgleaks.sh -o github -v -a "--config-path=gitleaks.toml"
  Scans the 'github' organization, enables verbosity and uses a configuration file

  orgleaks.sh -o github -v -a "--config-path=gitleaks.toml" --save-file orgleaks_report_github --format csv
  Scans the 'github' organization, enables verbosity, uses a configuration file and saves the report in csv format with provided name

_EOF_
  return
}

# Trap signals
trap "signal_exit TERM" TERM HUP
trap "signal_exit INT"  INT

# Parse command-line
while [[ -n $1 ]]; do
  case $1 in
    -h | --help)
      help_message; graceful_exit ;;
    -o | --org)
      shift; org="$1" ;;
    -v)
      args="${args} --verbose";;
    -a | --gitleaks-args)
      shift; args="${args} $1" ;;
    -s | --save-file)
      shift; fileName="$1" ;;
    -f | --format)
      shift; format="$1" ;;
    -* | --*)
      usage
      error_exit "Unknown option $1" ;;
    *)
      echo "Argument $1 to process..." ;;
  esac
  shift
done

# Add your github access token here, it is recommended to put an environment variable
access_token="youraccesstokengoeshere"

if [ "$org" == "" ]; then
  echo -e "ERROR: Organization name cannot be empty!"
  help_message; graceful_exit ;
else 
  dateTime=$(date '+%d-%m-%Y_%H:%M:%S')
  mkdir -p ./reports/"$org"/"$dateTime"
  pages=$(curl -H 'Authorization: token '"$access_token" -H 'Accept:application/vnd.github.VERSION.raw' -sI https://api.github.com/orgs/$org/repos\?per_page\=500  | grep "<https://api.github.com" | awk '{print $4}'| awk -F "=" '{print $3}' | sed 's/[^0-9]//g')
  if [ -z "$pages" ]
  then
      curl -H 'Authorization: token '"$access_token" -H 'Accept:application/vnd.github.VERSION.raw' -s https://api.github.com/orgs/$org/repos\?per_page\=500 | grep "full_name" | awk -v org="$org" -F"\"" '{print "https://github.com/"$4}' > ./reports/"$org"/"$dateTime"/$org-repos.txt
  else
      > ./reports/"$org"/"$dateTime"/$org-repos.txt
      for (( counter=1; counter<=$pages; counter++ ))
      do  
        curl -H 'Authorization: token '"$access_token" -H 'Accept:application/vnd.github.VERSION.raw' -s https://api.github.com/orgs/$org/repos\?per_page\=500\&page\=$counter | grep "full_name" | awk -v org="$org" -F"\"" '{print "https://github.com/"$4}' >> ./reports/"$org"/"$dateTime"/$org-repos.txt
      done
  fi
  if [ "$args" == "" ]; then
    if [ -z "$fileName" ]
    then
      while read -r line 
      do 
      gitleaks --repo-url="$line" --access-token=$access_token
      done < ./reports/"$org"/"$dateTime"/$org-repos.txt
    else  
      
      if [ -z "$format" ]
      then
          format="json"
      fi
      while read -r line
      do 
        localReport=$(echo "$line" | awk -F '/' '{print $5}')
        localPath=./reports/"$org"/"$dateTime"/"$localReport"."$format"
        gitleaks --repo-url="$line" --report="$localPath" --format="$format" --access-token=$access_token 
      done < ./reports/"$org"/"$dateTime"/$org-repos.txt
      cat ./reports/"$org"/"$dateTime"/*."$format" > ./reports/"$org"/"$dateTime"/"$fileName"."$format"
    fi
  else 
    if [ -z "$fileName" ]
    then
      while read -r line
        do gitleaks --repo-url="$line" --access-token=$access_token $args
      done < ./reports/"$org"/"$dateTime"/$org-repos.txt
    else
      if [ -z "$format" ]
      then
          format="json"
      fi
      while read -r line 
      do 
        localReport=$(echo "$line" | awk -F '/' '{print $5}')
        localPath=./reports/"$org"/"$dateTime"/"$localReport"."$format"
        gitleaks --repo-url="$line" --report="$localPath" --format="$format" --access-token=$access_token $args
      done < ./reports/"$org"/"$dateTime"/$org-repos.txt
      cat ./reports/"$org"/"$dateTime"/*."$format" > ./reports/"$org"/"$dateTime"/"$fileName"."$format"
    fi
  fi
fi


graceful_exit
