#!/bin/bash

# pacman-mirrorlist-update.sh: Fetch latest pacman mirrorlist and update packages
# Copyright (C) 2016  Clinton Wright
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.


# Bash script that will attempt to fetch latest ArchLinux Pacman mirrorlist and then synchronize and update the repos
# with the newly updated mirror list

# Define all variables and references to commands
tmpfile=/tmp/mirrorlist
sedtmpcheck=/tmp/sedcheck
pmconffile=/etc/pacman.d/mirrorlist
curl=$(which curl)
sed=$(which sed)
touch=$(which touch)
grep=$(which grep)
pacman=$(which pacman)

# URL used to fetch mirrorlist including all stable mirrors using http and https protocols
url="https://www.archlinux.org/mirrorlist/?country=all&protocol=http&protocol=https&ip_version=4&use_mirror_status=on"

checkFileDeleted()
{
    if [ -e $1 ]; then
        echo -e "File was not successfully deleted: $1"
    else
        echo -e "File was successfully deleted: $1"
    fi   
}

deleteFile()
{
    if [ -e $1 ]; then
        rm -f $1
        checkFileDeleted $1
    fi
}

confirmFileDelete()
{
    echo -e "Are you sure you want to remove the existing file $1? (Y/n):"
    read
    if [ -z $REPLY ]; then
        deleteFile $1
    elif [ $REPLY == "y" -o $REPLY == "Y" ]; then
        deleteFile $1
    elif [ $REPLY == "n" -o $REPLY == "N" ]; then
        echo -e "File not deleted: $1"
        exit 1
    else
        echo -e "Invalid input: $1"
    fi
}

# Check for the presence of the curl command
if [ ! -f $curl ]; then
	echo -e "The curl command could not be found at location: $curl"
	exit 1
fi

# Check for the presence of the sed command
if [ ! -f $sed ]; then
	echo -e "The sed command could not be found at location: $sed"
fi

# Check for the presence of the touch command
if [ ! -f $touch ]; then
	echo -e "The touch command could not be found at location: $touch"
fi

# Check for the presence of the grep command
if [ ! -f $grep ]; then
	echo -e "The grep command could not be found at location: $grep"
fi

# Check for the presence of the pacman command
if [ ! -f $pacman ]; then
	echo -e "The pacman command could not be found at location: $pacman"
fi

# Remove the temp mirrorlist file if it exists
if [ -e $tmpfile ]; then
    confirmFileDelete $tmpfile
fi

# Fetch and store mirrorlist
$curl -o $tmpfile $url

# Check if mirrorlist temp file exists
if [ -f $tmpfile ]; then

    # Remove the first hashtag at the start of each line from the mirrorlist file
	$sed -i s/^#//g $tmpfile
	
    # Check that the first character on each mirror line entry is not a hashtag
	sedtmpcheck=$($grep -Pi "^#s" $tmpfile)

    # Variable must be empty as grep result is expected to be empty to indicate success
	if [ -z "$sedtmpcheck" ]; then

        # Check if temp mirrorlist file is not 0 bytes
		if [ -s $tmpfile ]; then

			# Delete pacman mirrorlist file if it exists
			if [ -e $pmconffile ]; then
                confirmFileDelete $pmconffile
			fi

			# Copy newly generated pacman config file to /etc/pacman.d/mirrorlist
			mv $tmpfile $pmconffile

            # Run pacman sync and refresh packages from the server using the mirrorlists
			$pacman -Sy --noconfirm
		else
			echo -e "ERROR: Mirrorlist temp file is zero bytes"
			exit 1
		fi
	else
		echo -e "Sed operation to remove commented out mirror lines failed."
		exit 1
	fi
fi
exit 0

