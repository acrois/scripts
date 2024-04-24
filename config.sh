#!/usr/bin/env sh

DEST="$HOME/.profile"

if [ -f "$HOME/.bash_profile" ]; then
  DEST="$HOME/.bash_profile";
fi

# echo $DEST;
echo "\nsource $HOME/scripts/config/.profile\n" >> $DEST;
source $DEST;
