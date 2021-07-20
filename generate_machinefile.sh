#!/bin/bash


if find / -name "mpich" 2>/dev/null | grep "mpich" &>/dev/null; then # check for existance of mpich package files
    echo "found mpich package files"
    touch machinefile
    echo "master:1" >> machinefile
    for (( i=1; i<=$1; i++ )); do
        echo "worker"$i":1" >> machinefile
    done

elif find / -name "openmpi" 2>/dev/null | grep "openmpi" &>/dev/null; then # check for existance of openmpi package files
    echo "found openmpi package files"
    touch machinefile
    echo "master slots=1" >> machinefile
    for (( i=1; i<=$1; i++ )); do
        echo "worker"$i" slots=1" >> machinefile
    done
else
    echo "cannot find mpich or openmpi package files"
    exit 1
fi

