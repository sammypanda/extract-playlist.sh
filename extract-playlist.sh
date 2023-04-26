#!/bin/bash

# variables
working_dir=$(echo ${BASH_SOURCE[0]} | awk -F [a-z0-9\-]*[.]sh '{ print $1; print $3 }') # this doofus means we can't have more than one sh file in the working_dir
music_dir=/mnt/storage/Music
playlist=$1
mp3=false

# check functions
btchecks() {
    if ! command -v bluetooth-sendto > /dev/null; then
        echo "this script requires bluetooth-sendto"
        return 1
    elif ! command -v bluetoothctl > /dev/null; then
        echo "this script requires bluetoothctl"
        return 1
    else
        echo "⚠️  please make sure the intended device is paired already before using the bluetooth option"
    fi
}

outputchecks() {
    echo ""
}

playlistchecks() {
    if ! echo $playlist | grep ".m3u" > /dev/null; then
        echo "playlist must be an .m3u file"
        return 1
    fi
}

# check inputs/options
if [ -f "$playlist" ]; then
    if ! playlistchecks; then exit; fi
    echo -e "playlist: $playlist\n"
    shift
else
    echo "add the m3u file as the first param (^^)"
	exit 1
fi

while getopts b:O:m option
do 
    case "${option}"
        in
        b) bluetooth=${OPTARG} ;;
        O) output_dir=${OPTARG} ;;
        m) mp3=true ;;
    esac
done
shift $((OPTIND -1))

if [ -n "$bluetooth" ]; then 
    if ! btchecks; then exit; fi
fi

if [ -n "$output_dir" ]; then
    if ! outputchecks; then exit; fi
else
    exit
fi

# main loop process
IFS=$'\n'
x=0
# DEBUG: echo $(cat "$playlist")
for line in $(cat "$playlist"); do
    x=$((x+1))
    # DEBUG: echo $x
    # DEBUG: echo "$output_dir"/${line/*\//""}

    if [[ "$line" =~ "$music_dir" ]]; then

        if [ "$mp3" != false ]; then # convert the path
            line_but_mp3=${line/%"."*/".mp3"} # replace file extension with mp3
            path="$line_but_mp3"
        else # stay consistent to the true path $line from the m3u file
            path="$line"
        fi

        if [[ -f "$output_dir"/${path/*\//""} ]]; then
            echo -e "$(tput setaf 1)$path $(tput sgr0)(already exists)"
        else 
            echo -e "$(tput setaf 2)$path"

            if [ "$mp3" != false ]; then # only replace last instance of .flac/.wav/etc extension
                flatten_dir=${path/"/"*"/"/""} # remove all "/[and text here]/"
                ffmpeg -i "$line" "$output_dir/$flatten_dir" -y &> /dev/null
            else
                cp "$path" "$output_dir"
            fi

            if [ -n "$bluetooth" ]; then
                echo "reached"
                bluetooth-sendto --device $bluetooth $path
            fi
        fi
    fi
done
unset IFS

# finish notification
playlist=$(echo "$1" | cut -f  1 -d '.')
notify-send "$USER" "Playlist '$playlist' Synced"
