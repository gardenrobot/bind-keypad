#!/bin/bash

# set this to the id of the device found in /dev/input/by-id/
dev_id="$1"

# map the scenes to keys here. example:
#87 firstflooroff
#88 movie_night_1
#89 firstfloorbright
scene_map_file=$2
export scene_map=$(cat $scene_map_file)

# get token from https://homeassistant.example.com/profile/security
token_file=$3
export token=$(cat $token_file)


export scene_map
export endpoint=https://homeassistant.thepoly.cool/api/services/scene/turn_on

# hold the timestamp of the last time process_key ran. this is to avoid keyholding/mashing overloading the server with requests
export last_run_file=$(mktemp)
echo 0 > $last_run_file
# number of seconds to wait after last keypress to start processing keypresses again
export cooldown=1

function process_key {
    key=$1
    echo key: $key

    scene=$(echo "$scene_map" | grep "$key" | awk '{print $2}')

    if [[ -n $scene ]]
    then
        # check against last_run. Either exist, or update with current time and continue.
        current_time=$(date +%s)
        last_run=$(cat $last_run_file)
        if [[ "$last_run + $cooldown" -gt $current_time ]]
        then
            echo "Hasn't been $cooldown seconds since last run. Ignoring."
            exit 1
        else
            date +%s > $last_run_file
        fi

        echo scene: $scene
        curl -X POST -H "Authorization: Bearer $token" \
          -H "Content-Type: application/json" \
          -d "{\"entity_id\": \"scene.$scene\"}" \
          "$endpoint"
    else
        echo "Scene not found for key $key"
    fi
}
export -f process_key
evtest --grab "$dev_id" | grep --line-buffered "^Event:" | grep --line-buffered EV_MSC | sed --unbuffered 's/.*value //' | xargs -I {} bash -c 'process_key "{}"'
