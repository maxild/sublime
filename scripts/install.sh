#!/usr/bin/env sh

# See also
#    (i)  http://www.sublimetext.com/docs/3/settings.html
#    (ii) https://packagecontrol.io/docs/syncing

fail () {
  echo "$1" >&2
  exit 1
}

link() {
  from="$1"
  to="$2"
  echo "Symlink '$from' to '$to'"
  rm -rf "$to"
  ln -s "$from" "$to"
}

function get_abspath() {
  [[ ! -f "$1" ]] && return 1
  [[ -n "$no_symlinks" ]] && local pwdp='pwd -P' || local pwdp='pwd'
  echo "$( cd "$( echo "${1%/*}" )" 2>/dev/null; $pwdp )"/"${1##*/}" # echo result.
  return 0
}

ensureBash() {
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
}

main() {
  ensureBash

  scriptPath=$(get_abspath "${BASH_SOURCE}")
  scriptsFolder=$(dirname "${scriptPath}")
  root=$(dirname "${scriptsFolder}")

  userOsSettingsFolder="User (OS Settings)"
  userFolder="User"

  # path to this repos 'Packages/User (OS Settings)' and 'Packages/User' folders
  gitRepoUserOsSettingsFolder="$root/Packages/$userOsSettingsFolder"
  gitRepoUserFolder="$root/$userFolder"

  # path to ST3 data dir 'Packages/User (OS Settings)' and 'Packages/User' folders
  sublimeDataFolder="$HOME/Library/Application Support/Sublime Text 3"
  sublimePackagesFolder="${sublimeDataFolder}/Packages"
  sublimeUserOsSettingsFolder="$sublimePackagesFolder/$userOsSettingsFolder"
  sublimeUserFolder="$sublimePackagesFolder/$userFolder"

  # path to ST3 executable
  sublimeExe='/Application/Sublime Text.app/Contents/SharedSupport/bin/subl'

  # Check that ST3 settings really exist on this computer
  if [[ ! -e "${sublimePackagesFolder}" ]]; then
    fail "Could not find the ${sublimePackagesFolder} folder."
  fi

  #
  # Symlink for 'subl <path>' support on the command-line
  #

  # Set symlink for Sublime Text such that 'subl .' etc works in terminal
  [[ -e "$sublimeExe" ]] && link "$sublimeExe" "$HOME/bin/subl";

  #
  # Packages/User (OS Settings)
  #

  if [[ -e "$sublimeUserOsSettingsFolder" && ! -d "$sublimeUserOsSettingsFolder" ]]; then
    fail "Error: The path '$sublimeUserOsSettingsFolder' is not a directory."
  fi

  if [[ -L "$sublimeUserOsSettingsFolder" ]]; then
    echo "The folder '$sublimeUserOsSettingsFolder' is already a symlink."
  elif [[ -e "$sublimeUserOsSettingsFolder" ]]; then
    fail "Error: The folder '$sublimeUserOsSettingsFolder' already does exist, but it is NOT a symlink."
  else
    link "$gitRepoUserOsSettingsFolder" "$sublimeUserOsSettingsFolder"
  fi

  #
  # Packages/User
  #

  if [[ -e "$sublimeUserFolder" && ! -d "$sublimeUserFolder" ]]; then
    fail "Error: The path '$sublimeUserFolder' is not a directory."
  fi

  if [[ -L "${sublimeUserFolder}" ]] ; then
    echo "The folder '${sublimeUserFolder}' is already a symlink."
  else
    echo "The folder '$sublimeUserFolder' does exist and the folder is not a symlink......yet!"

    # rename/backup existing Packages/User folder
    mv "$sublimeUserFolder" "$sublimePackagesFolder/_User"
    echo "Renamed 'Packages/User' folder to 'Packages/_User' (i.e. created a backup)."

    # create symlink for Packages/User folder
    link "$gitRepoUserFolder" "$sublimeUserFolder"
  fi
}

main
