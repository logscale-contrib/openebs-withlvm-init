#!/bin/bash
echo BEGIN LIST OF NVME
nvme list
echo END LIST OF NVME

OUTPUT=$(vgscan 2> /dev/null | grep instancestore)
PLATFORM="${1:-aws}"
echo Platform is $PLATFORM
if [ $PLATFORM == aws ]; then
  condition="Instance"
elif [ $PLATFORM == azure ]; then
  condition="Microsoft NVMe Direct Disk"
else
  exit 1 #We should not be here
fi

if [ -z "$OUTPUT" ]
then
    echo "VG does not exist"
    declare -r disks=($(nvme list | grep "$condition" | cut -f 1 -d ' '))
    if (( ${#disks[@]} )); then
        for i in "${disks[@]}"
        do
            echo "Creating PV $i"
            pvcreate -ff -y $i
        done


        echo "Creating VG=instancestore $(printf '%s ' ${disks[@]})"
        vgcreate instancestore $(printf '%s ' ${disks[@]})
    fi
else
    echo "VG exists"
fi

sleep infinity
