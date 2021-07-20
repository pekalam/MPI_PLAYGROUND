#!/bin/bash

WAIT_FOR_TIMEOUT=40
NFS_TIMEOUT=40
MAX_RETRIES=3
WORKER_SUCCESS_PORT=2137

source /root/.bashrc
if ! command -v mpiCC &> /dev/null
then
    echo "mpiCC not found in PATH=$PATH"
    exit
fi


source /root/start_ssh.sh

eval `ssh-agent`
ssh-add /root/id_rsa

function setup_ssh {
    expect auto_ssh_send.exp "$1"
    ssh -q root@"$1" exit
    return $?
}

declare -a to_check_exit
for (( i=1; i<=$1; i++ )); do
    to_check_exit[$i]=1
done

man_exit=1
for (( i=1; i <= MAX_RETRIES; i++ )); do
    if [ "$2" == "worker" ] && ! [ "$man_exit" -eq 0 ]; then
        echo "Waiting for master :22 port"
        if wait-for.sh master:22 -t "$WAIT_FOR_TIMEOUT"; then
            echo "master wait success"
            setup_ssh "master"
            man_exit=$?
        else
            echo "master wait failure"
        fi
    fi

    for (( j=1; j<=$1; j++ )); do
        WORKER_NAME="worker$j"
        if [ "$WORKER_NAME" == "$3" ]; then
            to_check_exit[$j]=0
            continue
        fi
        echo "Waiting for $WORKER_NAME :22 port"
        if wait-for.sh "$WORKER_NAME":22 -t "$WAIT_FOR_TIMEOUT"; then
            echo "$WORKER_NAME wait success"
            setup_ssh "$WORKER_NAME"
            to_check_exit[$j]=$?
        else
            echo "$WORKER_NAME wait failure"
        fi
    done
    
    all_checked=1
    for (( j=1; j<=$1; j++ )); do
        
        if ! [ ${to_check_exit[$j]} -eq 0 ]; then
            echo "cannot connect to worker$j"
            all_checked=0
            break
        fi
    done

    if [ "$2" == "worker" ] && ! [ "$man_exit" -eq 0 ]; then
        echo "cannot connect to master"
        all_checked=0
    fi

    if [ "$all_checked" -eq 1 ]; then
        echo "SSH configuration complete"
        break
    fi


    if [ $i -eq $MAX_RETRIES ]; then
        echo "Reached max retries. Failing..."
        exit 1
    fi

    sleep 4
done


set -e

if [ "$2" == "master" ]; then
    echo "setting up nfs"
    source /root/master_nfs_setup.sh 
    #set working dir
    cd /cloud
    source /root/start_nfs_master.sh
    #compile hello-world example if it exist
    if [ -f hello-world.cpp ]; then
        echo "compiling hello-world example"
        mpiCC -o hello.exe hello-world.cpp
    fi
    
    if [ -f "machinefile" ]; then
        rm machinefile
    fi

    source /root/generate_machinefile.sh
    echo "generated machinefile:"
    cat machinefile

    for (( j=1; j<=$1; j++ )); do
        WORKER_NAME="worker$j"
        echo "Waiting for $WORKER_NAME :$WORKER_SUCCESS_PORT port"
        if wait-for.sh "$WORKER_NAME":$WORKER_SUCCESS_PORT -t "$WAIT_FOR_TIMEOUT"; then
            echo "$WORKER_NAME reported completed configuration"
        else
            echo "$WORKER_NAME success port wait failure"
            exit 1
        fi
    done

    echo "Running configuration test"
    bash /root/test_configuration.sh "$(($1+1))"
fi

if [ "$2" == "worker" ]; then
    
    for ((i=1; i<=MAX_RETRIES; i++)); do
        if wait-for.sh master:2049 -t "$NFS_TIMEOUT"; then
            break
        else
            echo "master's NFS port is not opened"
        fi
        if [ $i -eq $MAX_RETRIES ]; then
            echo "Reached max retries. Failing..."
            exit 1
        fi
        sleep 4
    done
    if ! [ -d "/cloud" ]; then
        mkdir /cloud
    fi
    echo "Mounting nfs directory"
    source /root/start_nfs_worker.sh
    cd /cloud

    echo "Starting to listen on success port"
    nc -l $WORKER_SUCCESS_PORT &
fi

echo "Configuration completed"

sleep inf
