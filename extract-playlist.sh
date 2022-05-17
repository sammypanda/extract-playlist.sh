#!/bin/sh

working_dir=$(echo ${BASH_SOURCE[0]} | awk -F [a-z0-9\-]*[.]sh '{ print $1; print $3 }') # this doofus means we can't have more than one sh file in the working_dir

music_dir=/run/media/sammypanda/Storage/Music
input=$1
output_dir=$2

if [ -n "$input" ]; then
    echo $input
else
    echo "add the m3u file as the first param (^^)"
	exit 1
fi

IFS=$'\n'
x=0
# DEBUG: echo $(cat "$playlist")
for line in $(cat "$playlist"); do
    x=$((x+1))
    # DEBUG: echo $x
    if [[ "$line" =~ "$music_dir" ]]; then
        echo $line
        cp "$line" "$output_dir"
    fi
done
unset IFS

playlist=$(echo "$1" | cut -f  1 -d '.')
notify-send "$USER" "Playlist '$playlist' Synced"

## at the moment the program outputs to the output folder, add an option 

path=$1


## to let the user type the path (/path/to/folder) where the output files go, as opposed to being put into output folder