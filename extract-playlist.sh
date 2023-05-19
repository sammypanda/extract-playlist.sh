#!/bin/bash

# variables
localPlaylist=$1
mp3=false
appData="$XDG_CONFIG_HOME/extract-playlist-script"
appDefaults="$appData/defaults.conf"

# init mechanisms
localSetup() {
	echo "-- starting setup --"

	if ! [ -a "$appDefaults" ]; then
		echo "no defaults found, creating..."
		mkdir -p "$appData"
		touch "$appDefaults"
	else
		source "$appDefaults"
	fi

	echo -e "$(tput clear)"

	read -p "Enter music_dir directory [$music_dir]: " Read_music_dir
	music_dir=${Read_music_dir:-$music_dir}

	echo "music_dir=$music_dir" > $appDefaults
}

if ! [ -a "$appDefaults" ]; then
	localSetup
else
	source "$appDefaults"
fi

# output functions
# $1 = bool for failed command attempt
localHelp() {
	local invalid=${1:-false}
	
	if $invalid; then
		echo "Unknown command :("
	fi

	echo -e "
		./extract-playlist.sh [path to m3u] [options]

		options:
		-O [directory]
		set the path to the output

		-b [device ID]
		send over bluetooth instead of into an output directory (requires gui intervention)

		-i
		(init) go through setup again
	"
}

while getopts ":hbOmi" option
do 
    case "${option}"
        in
	h) localHelp ;;
        b) bluetooth=${OPTARG} ;;
        O) output_dir=${OPTARG} ;;
        m) mp3=true ;;
	i) localSetup ;;
    esac
done
shift $((OPTIND -1))

# check functions
if [ -z "$localPlaylist" ]; then
	localPlaylist=$playlist
fi

if [ -z "$playlist" ]; then
	echo -e "$(tput setaf 1)\n !!! Could not find playlist, please add as first parameter or do the setup $(tput sgr0)"
	localHelp
fi

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

playlistchecks() {
    if ! echo $localPlaylist | grep ".m3u" > /dev/null; then
        echo "playlist must be an .m3u file"
        return 1
    fi
}

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
# echo $(cat "$localPlaylist") # DEBUG (dumps entire playlist in raw text)
for line in $(cat "$localPlaylist"); do
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
notify-send "$USER" "Playlist '$localPlaylist' Synced"
