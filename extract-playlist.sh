#!/bin/sh

working_dir=$(echo ${BASH_SOURCE[0]} | awk -F [a-z0-9\-]*[.]sh '{ print $1; print $3 }') # this doofus means we can't have more than one sh file in the working_dir

if [[ -d $working_dir/output ]]; then
    rm $working_dir/output/*.*
	rm -rf $working_dir/output/.meta
else
    mkdir $working_dir/output
fi

mkdir $working_dir/output/.meta

music_dir=/run/media/sammypanda/Storage/Music
meta_dir=/run/media/sammypanda/Storage/Music/.meta
input=$1

if [ -n "$input" ]; then
    echo $input
else
    echo "add the m3u file as the first param (^^)"
	exit 1
fi

IFS=$'\n'
x=0
for line in $(cat "$input"); do
    x=$((x+1))
    # echo $x
    if [[ "$line" =~ "$music_dir" ]]; then
        echo $line
        cp "$line" "$working_dir/output"
    fi
done
unset IFS

if [ -n "$meta_dir" ]; then
    rm -rf $working_dir/output/.meta/*
    cp -r "$meta_dir" "$working_dir/output"
else
    mkdir $working_dir/output/.meta
    if [ -d $working_dir/output/.meta/playlists ]; then
        rm -rf $working_dir/output/.meta/playlists
    fi
    # cp -r "$playlist_dir" "$working_dir/output/.meta/playlists"
fi

playlist=$(echo "$1" | cut -f  1 -d '.')
notify-send "$USER" "Playlist '$playlist' Synced"
