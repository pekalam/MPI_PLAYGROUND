#!/bin/bash

WAIT_FOR_TIMEOUT=10
NFS_TIMEOUT=10
MAX_RETRIES=5


service ssh restart

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
    #set working dir
    cd /cloud
    exportfs -a
    service rpcbind restart
    service nfs-kernel-server restart
    #compile hello-world example if it exist
    if [ -f hello-world.cpp ]; then
        echo "compiling hello-world example"
        mpiCC -o hello.exe hello-world.cpp
    fi
    
    if [ -f "machinefile" ]; then
        rm machinefile
    fi

    touch machinefile
    echo "master" >> machinefile
    for (( i=1; i<=$1; i++ )); do
        echo "worker"$i >> machinefile
    done
    echo "generated machinefile:"
    cat machinefile
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
    service rpcbind restart
    mount -t nfs master:/cloud /cloud
    cd /cloud
fi

echo "Configuration complete"

sleep inf
