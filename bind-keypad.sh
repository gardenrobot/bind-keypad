#!/bin/bash

# map the scenes to keys here
read -r -d '' scene_map <<EOF
87 firstflooroff
88 movie_night_1
89 firstfloorbright
EOF

# set this to the human readable name of the keyboard using `xinput list`
dev_name="SIGMACHIP USB Keyboard  "

# get token from https://homeassistant.thepoly.cool/profile/security
export token="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiI3MWQ5YTc5NzJkYjE0ZGZjYWE4MTZjYWQ4YTQ5YjAzYyIsImlhdCI6MTc0MDY3NjkwNSwiZXhwIjoyMDU2MDM2OTA1fQ.yEuwSAgdbqqUqaoPx90B2cROG3puXUXqQS3RZKKVDOY"


export scene_map
export endpoint=https://homeassistant.thepoly.cool/api/services/scene/turn_on
dev_id=$(xinput list | grep "$dev_name" | tail -n 1 | sed -r 's/.*id=([[:digit:]]+).*/\1/')

function process_key {
    key=$(echo "$1" | sed 's/key release //')
    echo key: $key

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
