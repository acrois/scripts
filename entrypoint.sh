#!/usr/bin/env bash
set -exao pipefail

# Concatenate all arguments into a single string
CMD="$*"

# if ! command -v calver &> /dev/null
# then
#   echo "Commands could not be found, sourcing profile"
#   source ~/scripts/config/.profile
# fi

# Execute the command string in a login shell
exec bash -l -c "$CMD"
