#!/usr/bin/env bash
set -exao pipefail

# Concatenate all arguments into a single string
CMD="$*"

# if ! command -v calver &> /dev/null
# then
#   source ~/scripts/config/.profile
# fi

if [ ! -f ~/scripts/config/.profile ]; then
  echo "Commands could not be found, copying to home"
  cp -r /etc/skel/. ~
fi

# Execute the command string in a login shell
exec bash -l -c "$CMD"
