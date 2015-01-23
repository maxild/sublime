#!/usr/bin/env sh

# No Warranty! Use on your own risk.
# Take backup of Library/Application Support/Sublime Text 3 folder first.

# TODO: use rsync to update Packages/Javascript etc...
#    start with only include snippets (and exclude everything else)
#    --include="*.sublime-snippet" --exclude="*"
# Note: Packages/User is already symlinked to repo. But automate this below in script.

fail () {
  echo "$1" >&2
  exit 1
}

if [ -z "$BASH" ]; then
  fail "The $0 command must be run with bash."
fi

shell=$(basename "$SHELL")
case "$shell" in
  bash) ;;
  *)
    fail "The $0 command only support the bash shell."
    ;;
esac

# Try to figure out the OS
uname="$(uname -a)"
os=
case "$uname" in
  Linux\ *) os="linux" ;;
  Darwin\ *) os="macosx" ;;
esac

sublimeDataDir=
# Where are Sublime settings installed
if [[ $os == "macosx" ]];then
  sublimeDataDir="$HOME/Library/Application Support/Sublime Text 3"
# elif [ `uname` = "linux" ];then
  # SOURCE="$HOME/.config/sublime-text-2"
else
  fail "Unknown operating system."
fi

# Check that settings really exist on this computer
if [[ ! -e "${sublimeDataDir}/Packages/" ]]; then
  fail "Could not find the ${sublimeDataDir}/Packages/ folder."
fi

# Detect that we don't try to install twice and screw up
if [[ -L "${sublimeDataDir}/Packages/User" ]] ; then
  fail "The ${sublimeDataDir}/Packages/User folder is already symlinked."
fi

# Git project (or dropbox) folder
syncFolder="$HOME/Projects/sublime"

# Dropbox has not been set-up on any computer before?
if [[ ! -e "$syncFolder" ]] ; then
  echo "Setting up Git sync folder $syncFolder"
  mkdir -- "$syncFolder"
  cp -R -- "$sublimeDataDir/Packages/User" "$syncFolder"
fi

# Now when settings are in sync rename (backup) and delete Packages/User folder
mv -- "$sublimeDataDir/Packages/User" "$sublimeDataDir/Packages/_User"
rm -rf "$sublimeDataDir/Packages/User"

# Symlink Packages/User folder
ln -s "$syncFolder/Packages/User" "$sublimeDataDir/Packages/User"

unset -f fail
