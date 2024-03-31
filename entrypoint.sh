#!/usr/bin/env bash

# Concatenate all arguments into a single string
CMD="$*"

# Execute the command string in a login shell
exec bash -l -c "$CMD"
