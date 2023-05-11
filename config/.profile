# set PATH to include shell scripts
if [ -d "$HOME/scripts/shell" ] ; then
    export PATH="$HOME/scripts/shell:$PATH"
fi

# Alternative path :)
if [ -d "/mnt/c/Projects/scripts/shell" ] ; then
    export PATH="/mnt/c/Projects/scripts/shell:$PATH"
fi
