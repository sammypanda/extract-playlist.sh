#!/bin/bash

# variables
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
# echo $(cat "$playlist") # DEBUG (dumps entire playlist in raw text)
for line in $(cat "$playlist"); do
    x=$((x+1))
    # echo $x # DEBUG (shows line number)
    # echo "$output_dir"/${line/*\//""} # DEBUG

    path=`find $music_dir -maxdepth 2 -name "*${line/*\//}*"`

    if [[ $path ]]; then

        if [ "$mp3" != false ]; then # convert the path
            path_but_mp3=${path/%"."*/".mp3"} # replace file extension with mp3
            path="$path_but_mp3"
        else # stay consistent to the true path $line from the m3u file
            path="$path"
        fi

        if [[ -f "$output_dir"/${path/*\//""} ]]; then
            echo -e "$(tput setaf 1)$path $(tput sgr0)(already exists)"
        else 
            echo -e "$(tput setaf 2)$path"

            if [ "$mp3" != false ]; then # only replace last instance of .flac/.wav/etc extension
                flatten_dir=${path/"/"*"/"/""} # remove all "/[and text here]/"
                ffmpeg -i "$path" "$output_dir/$flatten_dir" -y &> /dev/null
            else
                cp "$path" "$output_dir"
            fi

            if [ -n "$bluetooth" ]; then
                echo "reached"
                bluetooth-sendto --device $bluetooth $path
            fi
        fi

    else
        echo "could not find ${line/*\//} in $music_dir"
    fi
done
unset IFS

# finish notification
playlist=$(echo "$1" | cut -f  1 -d '.')
notify-send "$USER" "Playlist '$playlist' Synced"
