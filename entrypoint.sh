#!/bin/bash

declare -A log_levels=( [FATAL]=0 [ERROR]=3 [WARNING]=4 [INFO]=6 [DEBUG]=7)
if ! command -v date &> /dev/null
then
    echo "date could not be found"
    exit
fi
if ! command -v jq &> /dev/null
then
    echo "jq could not be found"
    exit
fi
json_logger() {
  log_level=$1
  message=$2
  level=${log_levels[$log_level]}
  timestamp=$(date -I'ns')
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

if ! command -v nvme &> /dev/null
then
    echo "nvme could not be found" | json_logger "FATAL"
    exit
fi
if ! command -v grep &> /dev/null
then
    echo "grep could not be found" | json_logger "FATAL"
    exit
fi
if ! command -v cut &> /dev/null
then
    echo "cut could not be found" | json_logger "FATAL"
    exit
fi
if ! command -v vgscan &> /dev/null
then
    echo "vgscan could not be found" | json_logger "FATAL"
    exit
fi
if ! command -v vgcreate &> /dev/null
then
    echo "vgcreate could not be found" | json_logger "FATAL"
    exit
fi
if ! command -v pvcreate &> /dev/null
then
    echo "pvcreate could not be found" | json_logger "FATAL"
    exit
fi
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



trap '' INT TERM
sleep infinity & pid=$!

while wait $pid; test $? -ge 128
do echo 'exiting' | json_logger "INFO"
done
