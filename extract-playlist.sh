#!/bin/sh

working_dir=$(echo ${BASH_SOURCE[0]} | awk -F [a-z0-9\-]*[.]sh '{ print $1; print $3 }') # this doofus means we can't have more than one sh file in the working_dir

music_dir=/run/media/sammypanda/Storage/Music
input=$1

if [ -n "$input" ]; then
    echo $input
else
    echo "add the m3u file as the first param (^^)"
	exit 1
fi

IFS=$'\n'
x=0
# echo $(cat "$input")
for line in $(cat "$input"); do
    x=$((x+1))
    # echo $x
    if [[ "$line" =~ "$music_dir" ]]; then
        echo $line
        cp "$line" "$working_dir/output"
    fi
done
unset IFS

playlist=$(echo "$1" | cut -f  1 -d '.')
notify-send "$USER" "Playlist '$playlist' Synced"
