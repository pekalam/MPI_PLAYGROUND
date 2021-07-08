#!/bin/bash
set -e
docker exec manager mpiCC -o /cloud/$1.exe /cloud/$1.cpp
docker exec manager mpirun -machinefile /cloud/machinefile -np $2 /cloud/$1.exe