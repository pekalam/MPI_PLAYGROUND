#!/bin/bash

echo "
worker$1:
    hostname: worker$1
    container_name: worker$1
    image: mpi-ubuntu
    command: $1 worker worker$1
    cap_add: 
        - SYS_ADMIN
    environment: 
        - NO_CHECKPOINTS=1
    deploy:
        placement:
          constraints:
            - \"node.role==worker\"
"