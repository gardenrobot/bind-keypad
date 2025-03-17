#!/bin/bash

# set this to the human readable name of the keyboard using `xinput list`
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
export last_run_file=mktemp
date +%s > $last_run_file
# number of seconds to wait after last run to start running again
export interval=2

function process_key {
    key=$(echo "$1" | sed 's/key release //')
    echo key: $key

    # check against last_run. Either exist, or update with current time and continue.
    current_time=$(date +%s)
    last_run=$(cat $last_run_file)
    if [[ "$last_run + $interval" -gt $current_time ]]
    then
        echo "Hasn't been $interval seconds since last run. Ignoring."
        exit 1
    else
        date +%s > $last_run_file
    fi

    scene=$(echo "$scene_map" | grep "$key" | awk '{print $2}')

    if [[ -n $scene ]]
    then
        echo scene: $scene
        curl -X POST -H "Authorization: Bearer $token" \
          -H "Content-Type: application/json" \
          -d "{\"entity_id\": \"scene.$scene\"}" \
          "$endpoint"
    else
        echo Scene not found
    fi
}
export -f process_key
xinput test $dev_id | ag 'key release ' | xargs -I {} bash -c 'process_key "{}"'
