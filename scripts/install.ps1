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

function Get-Basename ($path) { Split-Path -parent $path }

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
    if (Test-Path -Path $target -PathType Container)
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
    if (Test-Path -Path $link -PathType Container)
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
	$scriptsFolder = Get-Basename $PSCommandPath
	$root = Get-Basename $scriptsFolder
	$gitRepoUserFolder = Join-Path $root "User"

	# Path to Sublime Text Packages/User folder
	$sublimePackagesFolder = "${env:AppData}\Sublime Text 3\Packages"
	$sublimeUserFolder = Join-Path "$sublimePackagesFolder" "User"

	if ( !(Test-Path -PathType Container $sublimeUserFolder) ) {
		echo "The folder $sublimeUserFolder does not exist."
	}
	elseif ( !(Test-SymLink $sublimeUserFolder) ) {
		echo "The folder $sublimeUserFolder does exist and the folder is not a symlink."

		# rename/backup existing Packages/User folder
		Rename-Item -Path "$sublimeUserFolder" -NewName "_User"

		# create symlink for Packages/User folder
		#Remove-SymLink "$sublimeUserFolder"
		New-SymLink "$sublimeUserFolder" "$gitRepoUserFolder"
	}
	else {
		echo "The folder $sublimeUserFolder is already a symlink."
	}
}

Main
