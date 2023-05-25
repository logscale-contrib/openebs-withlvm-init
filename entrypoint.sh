#!/bin/bash

declare -A log_levels=( [FATAL]=0 [ERROR]=3 [WARNING]=4 [INFO]=6 [DEBUG]=7)
json_logger() {
  log_level=$1
  message=$2
  level=${log_levels[$log_level]}
  timestamp=$(date --iso-8601=seconds)
  jq --raw-input --compact-output \
    '{
      "level": '$level',
      "timestamp": "'$timestamp'",
      "message": .
    }'
}

trap 'catch $? $LINENO' ERR

catch() {
  echo "Error $1 occurred on $2" | json_logger "FATAL"
  exit 1
}

echo Platform is $PLATFORM | json_logger "INFO"
nvme list | json_logger "INFO"
OUTPUT=$(vgscan 2> /dev/null | grep instancestore)
PLATFORM="${1:-aws}"
if [ $PLATFORM == aws ]; then
  condition="Instance"
elif [ $PLATFORM == azure ]; then
  condition="Microsoft NVMe Direct Disk"
elif [ $PLATFORM == gcp ]; then
  condition="nvme_card"
else
  echo PLATFORM IS UNKNOWN | json_logger "FATAL"
  exit 1 #We should not be here
fi

if [ -z "$OUTPUT" ]
then
    echo "VG does not exist" | json_logger "INFO"
    declare -r disks=($(nvme list | grep "$condition" | cut -f 1 -d ' '))
    if (( ${#disks[@]} )); then
        for i in "${disks[@]}"
        do
            echo "Creating PV $i" | json_logger "INFO"
            pvcreate -ff -y $i
        done


        echo "Creating VG=instancestore $(printf '%s ' ${disks[@]})" | json_logger "INFO"
        vgcreate instancestore $(printf '%s ' ${disks[@]}) | json_logger "INFO"
    fi
else
    echo "VG exists" | json_logger "INFO"
fi

sleep infinity
