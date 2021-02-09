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
# 2021-02-09 Support for pages
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
  -o, --org, github  Organization Name
      where 'github' is the Organization Name.
  -v  verbose
  -a, --gitleaks-args, "--report=org-gitleaks-result --format=csv"
      where '"--report=org-gitleaks-result --format=csv"' are the arguments for Gitleaks
      refer to https://github.com/zricethezav/gitleaks/wiki/Scanning

  Examples:

  orgleaks.sh -o github
  Scans the 'github' organization

  orgleaks.sh -o github -v 
  Scans the 'github' organization and enables verbosity for gitleaks

  orgleaks.sh -o github -v -a "--report=github-gitleaks-result.csv --format=csv"
  Scans the 'github' organization, enables verbosity and save the report in csv format with provided name

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
  pages=$(curl -H 'Authorization: token '"$access_token" -H 'Accept:application/vnd.github.VERSION.raw' -sI https://api.github.com/orgs/$org/repos\?per_page\=500  | grep "Link: <https://api.github.com" | awk '{print $4}' | grep -E -o '&page=\d+>;' | grep -E -o '[0-9]+')
  if [ -z "$pages" ]
  then
      curl -H 'Authorization: token '"$access_token" -H 'Accept:application/vnd.github.VERSION.raw' -s https://api.github.com/orgs/$org/repos\?per_page\=500 | grep "full_name" | awk -v org="$org" -F"\"" '{print "https://github.com/"$4}' > $org-repos.txt
  else
      > $org-repos.txt
      for (( counter=1; counter<=$pages; counter++ ))
      do  
        curl -H 'Authorization: token '"$access_token" -H 'Accept:application/vnd.github.VERSION.raw' -s https://api.github.com/orgs/$org/repos\?per_page\=500\&page\=$counter | grep "full_name" | awk -v org="$org" -F"\"" '{print "https://github.com/"$4}' >> $org-repos.txt
      done
  fi
  if [ "$args" == "" ]; then
    while read -r line; do gitleaks --repo-url="$line" --access-token=$access_token; done < $org-repos.txt
  else 
    while read -r line; do gitleaks --repo-url="$line" --access-token=$access_token $args; done < $org-repos.txt
  fi
fi


graceful_exit

