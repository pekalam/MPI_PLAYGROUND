#!/bin/bash

echo "version: '3.4'"
echo "services:"
echo "
    master:
        hostname: master
        container_name: master
        command: $1 master
        build: 
            context: .
            dockerfile: Dockerfile
            args:
                mpirole: master
        cap_add: 
            - SYS_ADMIN
        image: mpi-ubuntu
        volumes: 
            - \"./cloud:/cloud\"
        deploy:
            placement:
              constraints:
                - \"node.role==master\"
"
echo ""

for ((i=1; i<=$1; i++ )); do

    echo "
    worker$i:
        hostname: worker$i
        container_name: worker$i
        image: mpi-ubuntu
        command: $1 worker worker$i
        cap_add: 
            - SYS_ADMIN
        deploy:
            placement:
                constraints:
                    - \"node.role==worker\"
    "

done