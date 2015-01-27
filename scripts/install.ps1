  #
# Script to backup the old Packages/User folder setup and
# create new Packages/User folder that is a symlink to
# this repos User folder.
#
# Before using this script do the following (to start ST3 with a clean slate)
#   1) Close Sublime Text
#   2) Delete (or rename) Packages folder
#   3) Start Sublime Text
#   4) Install Package Control
#

function Get-Dirname ($path) { Split-Path -parent $path }

# http://stackoverflow.com/questions/817794/find-out-whether-a-file-is-a-symbolic-link-in-powershell
function Test-SymLink([string]$path) {
    if (!(Test-Path $path)) {
      return $false;
    }
    $file = Get-Item $path -Force -ea 0
    return [bool]($file.Attributes -band [IO.FileAttributes]::ReparsePoint)
}

function New-SymLink ($link, $target)
{
    if ( (Get-Item $target) -is [System.IO.DirectoryInfo] )
    {
        $command = "cmd /c mklink /d"
    }
    else
    {
        $command = "cmd /c mklink"
    }

    Invoke-Expression "$command '$link' '$target'"
}

function Remove-SymLink ($link)
{
    if (Test-Path -Path "'$link'" -PathType Container)
    {
      # If you have a symbolic link that is a directory (made with mklink /d)
      # then using del will delete all of the files in the target directory
      # (the directory that the link points to), rather than just the link.
      # SOLUTION: rmdir on the other hand will only delete the directory link,
      # not what the link points to.

      $command = "cmd /c rmdir"
    }
    else
    {
      $command = "cmd /c del"
    }

    Invoke-Expression "$command '$link'"
}

function Main {
  # Path to git repo Packages/User folder (source)
  $scriptsFolder = Get-Dirname "$PSCommandPath"
  $root = Get-Dirname "$scriptsFolder"

  $userOsSettingsFolder="User (OS Settings)"
  $userFolder="User"

  # path to this repos 'Packages/User (OS Settings)' and 'Packages/User' folders
  $gitRepoUserOsSettingsFolder = Join-Path "$root" "Packages\$userOsSettingsFolder"
  $gitRepoUserFolder = Join-Path "$root" "$userFolder"

  # path to ST3 data dir 'Packages/User (OS Settings)' and 'Packages/User' folders
  $sublimeDataFolder = Join-Path "${env:AppData}" "Sublime Text 3"
  $sublimePackagesFolder = Join-Path "$sublimeDataFolder" "Packages"
  $sublimeUserOsSettingsFolder = Join-Path "$sublimePackagesFolder" "$userOsSettingsFolder"
  $sublimeUserFolder = Join-Path "$sublimePackagesFolder" "$userFolder"

  #
  # Packages/User (OS Settings)
  #

  if ( Test-Path $sublimeUserOsSettingsFolder -and !(Test-Path -PathType Container $sublimeUserOsSettingsFolder) ) {
      echo "Error: he path '$sublimeUserOsSettingsFolder' is not a directory."
      exit
  }

  if ( Test-SymLink "$sublimeUserOsSettingsFolder" ) {
      echo "The folder '$sublimeUserOsSettingsFolder' is already a symlink."
  }
  elseif ( Test-Path "$sublimeUserOsSettingsFolder") {
      echo "Error: The folder '$sublimeUserOsSettingsFolder' already does exist, but it is NOT a symlink."
      exit
  }
  else {
      New-SymLink "$sublimeUserOsSettingsFolder" "$gitRepoUserOsSettingsFolder"
  }

  #
  # Packages/User
  #

  if ( Test-Path $sublimeUserFolder -and !(Test-Path -PathType Container $sublimeUserFolder) ) {
      echo "Error: he path '$sublimeUserFolder' is not a directory."
      exit
  }

  if ( Test-SymLink $sublimeUserFolder ) {
    echo "The folder '$sublimeUserFolder' is already a symlink."
  }
  else {
    echo "The folder '$sublimeUserFolder' does exist and the folder is not a symlink......yet!"

    # rename/backup existing Packages/User folder
    Rename-Item -Path "$sublimeUserFolder" -NewName "_User"
    echo "Renamed 'Packages/User' folder to 'Packages/_User' (i.e. created a backup)."

    # create symlink for Packages/User folder
    New-SymLink "$sublimeUserFolder" "$gitRepoUserFolder"
  }
}

Main
