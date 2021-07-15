#!/bin/bash
set -e
docker exec master mpiCC -o /cloud/$1.exe /cloud/$1.cpp
docker exec master mpirun -machinefile /cloud/machinefile -np $2 /cloud/$1.exe